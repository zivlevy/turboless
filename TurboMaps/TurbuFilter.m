//
//  TurboFinder.m
//  readturbo
//
//  Created by Ziv Levy on 8/22/15.
//  Copyright (c) 2015 ZivApps. All rights reserved.
//

#import "TurbuFilter.h"
#import "Const.h"
#import "Turbulence.h"
#import "LocationManager.h"
#import "RecorderManager.h"

#define TH1 1.025
#define TH2 1.06
#define TH3 1.11
#define TH4 1.17
#define TH5 1.47
#define TH6 1.87

#define NUM_SUSPECT_TO_TURBULENCE 8
#define NUM_SUSPECT_MISS_TO_COOL 1

#define NUM_MISS_TURBULENCE_TO_END 0 //how many miss in turbulence to declare end of current turbulence
#define NUM_TURBULENCE_TO_DECLARE_VALID 2
#define TIME_WINDOW_TURBULENCE_TO_DECLARE_VALID 50


@interface TurbuFilter()

@property (nonatomic,strong) AccelerometerEvent * currentEvent;
@property bool inTurbulenceSuspect;
@property int turbulenceSuspectCount;
@property int suspectMissCount;

@property double currentTurbulencePeak;

@property bool inTurbulence;
@property int currentTurbulenceCount;
@property int turbulenceMissCount;
@property long lastTurbulenceTimpStemp;
@property double pwr0;

@property int noOfTurbulenceTotal;
@end

@implementation TurbuFilter
- (id)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceInMotion:) name:kNotification_DeviceInMotion object:nil];
    return self;
}

-(void) dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

#pragma mark - notification manager
-(void)deviceInMotion:(NSNotification *) notification {
    _inTurbulence = false;
    _inTurbulenceSuspect = false;
}

#pragma mark - filter logic
-(int)turbulenceLevel:(double) pwr
{
    //    if (pwr > TH6) {
    //        return 6;
    //    }
    if (pwr > TH5) {
        return 5;
    }
    if (pwr > TH4) {
        return 4;
    }
    if (pwr > TH3) {
        return 3;
    }
    if (pwr > TH2) {
        return 2;
    }
    if (pwr > TH1) {
        return 1;
    }
    return 0;
}
-(void)proccesInput:(AccelerometerEvent *) event
{
    _currentEvent = event;
    if (!_inTurbulenceSuspect && ! _inTurbulence) {
        [self inCoolState];
    } else if (_inTurbulenceSuspect) {
        [self insuspectState];
    } else if (_inTurbulence) {
        [self inTurbulenceState];
        
    }
    
}
//////////////
-(void)inCoolState
{
    double pwr= _currentEvent.g;
    if ([self isTurbulenceFilter:pwr]) {
        _inTurbulenceSuspect = true;
        _turbulenceSuspectCount=1;
        double absPwr = pwr < 0 ? -pwr : pwr;
        _currentTurbulencePeak = absPwr;
    }
}

-(void)insuspectState
{
    double pwr= _currentEvent.g;
    if ([self isTurbulenceFilter:pwr]) {
        _turbulenceSuspectCount ++;
        double absPwr = pwr < 0 ? -pwr : pwr;
        if (_currentTurbulencePeak < absPwr) _currentTurbulencePeak = absPwr;
        if (_turbulenceSuspectCount > NUM_SUSPECT_TO_TURBULENCE) {
            _inTurbulence = true;
        }
        _suspectMissCount=0;
    } else {
        _suspectMissCount++;
        if (_suspectMissCount > NUM_SUSPECT_MISS_TO_COOL) {
            _inTurbulenceSuspect = false;
            
            
        }
    }
}

-(void)inTurbulenceState
{
    double pwr= _currentEvent.g;
    if ([self isTurbulenceFilter:pwr]) {
        double absPwr = pwr < 0 ? -pwr : pwr;
        if (_currentTurbulencePeak < absPwr) _currentTurbulencePeak = absPwr;
        _turbulenceMissCount=0;
    } else {
        _turbulenceMissCount++;
        if (_turbulenceMissCount > NUM_MISS_TURBULENCE_TO_END) {
            _inTurbulence = false;
            _inTurbulenceSuspect = false;
            //report
            NSString *strDate = [NSString stringWithFormat:@"%@",[NSDate dateWithTimeIntervalSince1970:_currentEvent.timeStamp]];
            _noOfTurbulenceTotal++;
            
            //if this event is closer to last it is valid
            if ((_currentEvent.timeStamp - _lastTurbulenceTimpStemp) < TIME_WINDOW_TURBULENCE_TO_DECLARE_VALID) {
                NSLog (@"%i --- Turbulence level %i @ %@",_noOfTurbulenceTotal, [self turbulenceLevel:_currentTurbulencePeak] , strDate );
                
                
                
                    
                    TurbulenceEvent * event =[TurbulenceEvent new];
                    
                    // find current location
                    ZLTile tile = [[LocationManager sharedManager] getCurrentTile];
                    event.tileX=tile.x;
                    event.tileY=tile.y;
                    event.altitude=tile.altitude;
                    
                    //TODO
                    // check for valid altitude
                    if (event.altitude <=0 || event.altitude>kAltitude_NumberOfSteps) {

                    }
                    event.severity=[self turbulenceLevel:_currentTurbulencePeak];
                    event.isPilotEvent = NO;
                    
                    event.flightNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"flightNumber"];

                    NSDate * now = [NSDate date];
                    event.date = now;
                    
                    
                    event.userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"userName"];
                    if (event.severity >0) {
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [[RecorderManager sharedManager] writeTurbulenceEvent:event];
                            [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_TurbulenceEvent object:event userInfo:nil];
                        });
                    }
                    
           
            }
            _lastTurbulenceTimpStemp =_currentEvent.timeStamp;
            _currentTurbulencePeak = 0;
            
        }
    }
}

-(bool) isTurbulenceFilter:(double) pwr
{
    pwr-=1;
    
    // Do a simple Low pass filter
    _pwr0 = 0.9 * _pwr0 + 0.1 * pwr;
    
    //    // calc abs
    if (_pwr0 < 0)
        _pwr0 = -_pwr0;
    //////////////
    if (_pwr0 > TH1 -1) {
        return true;
    }else {
        return false;
    }
    
}
@end
