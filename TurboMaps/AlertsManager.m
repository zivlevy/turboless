//
//  AlertsManager.m
//  TurboMaps
//
//  Created by Ziv Levy on 9/15/15.
//  Copyright (c) 2015 ZivApps. All rights reserved.
//

#import "AlertsManager.h"
#import "Const.h"
#import "LocationManager.h"
#import "MapUtils.h"
#import "Turbulence.h"
#import "TurbulenceManager.h"



@interface AlertsManager()

@property (nonatomic,strong) NSTimer * timer;

@property (nonatomic,strong) NSArray * arrTurbelenceBelow;
@property (nonatomic,strong) NSArray * arrTurbelenceAt;
@property (nonatomic,strong) NSArray * arrTurbelenceAbove;

@property bool isUserAccepted;
@property bool isUserReset;

@property (nonatomic)  long cutOffTime ;//what is the oldest turbulence leagal for alert
@end


@implementation AlertsManager
+ (AlertsManager *)sharedManager {
    static AlertsManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (id)init {
    if (self = [super init]) {
        //init with no allert state
        [self setState_NoAlert];
        
        _isUserAccepted = false;
        _isUserReset = false;
        _cutOffTime = 0;

        _timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self
                                                selector:@selector(timerTick:) userInfo:nil repeats:YES];
    }
    return self;
}


#pragma mark - timer 
-(void) timerTick:(NSTimer *) timer {
    [self alertCycle];
}
# pragma mark - logic
-(void) tilesInAlertAreaWithLocation:(CLLocation *) location
{
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{ 
    NSMutableDictionary * tilesInRigionBelow = [NSMutableDictionary new];
    NSMutableDictionary * tilesInRigionAt = [NSMutableDictionary new];
    NSMutableDictionary * tilesInRigionAbove = [NSMutableDictionary new];
    
    bool isAltitudeLeagal = DEBUG_MODE ? true : location.altitude > kAltitude_Min * FEET_PER_METER ;
    
    bool isGoodLocation = [LocationManager sharedManager].isLocationGood ;
    bool isGoodCourse = [LocationManager sharedManager].isHeadingGood;
    
    if (DEBUG_MODE) {
        isGoodCourse = true;
    }
    
    //if we are above min altitude and there is leagal course
    if ( isAltitudeLeagal && isGoodCourse && isGoodLocation) {
        for (int az = -kAlertAngle; az <=kAlertAngle; az+=5) {
            double currentCalcCourse =location.course + az;
            
            //correct to 0-359
            if (currentCalcCourse >=360) currentCalcCourse -= 360;
            if (currentCalcCourse <=0) currentCalcCourse=360 + currentCalcCourse;
            //step every 5 miles to make sure we cover all tiles in range
            for (float i=0; i<=kAlertRange; i+=5) {
                //get cordinate
                CLLocationCoordinate2D stepWP = [MapUtils NewLocationFrom:location.coordinate atDistanceInMiles:i alongBearingInDegrees:currentCalcCourse];//currentLocation.course];
                //convert to location
                CLLocation * stepLocation = [[CLLocation alloc] initWithCoordinate:stepWP altitude:location.altitude horizontalAccuracy:0 verticalAccuracy:0 timestamp:[NSDate date]];
                
                //get the tile at that location
                ZLTile tile = [[LocationManager sharedManager] getTileForLocation:stepLocation];
                
                //get turbulence info at tile
                Turbulence * turbulence = [[TurbulenceManager sharedManager] getTurbulanceAtTile:tile];
                //if there is no turbelence at that tile of the turbulence is too old insert blank turbulence
                if (!turbulence || [[NSDate date] timeIntervalSince1970] - turbulence.timestamp > _cutOffTime) {
                    turbulence = [Turbulence new];
                    turbulence.tileX=tile.x;
                    turbulence.tileY=tile.y;
                    turbulence.altitude = tile.altitude;
                    turbulence.severity = 0;
                    turbulence.timestamp = 0;
                    
                }
                
                [tilesInRigionAt setObject:turbulence forKey:[NSString stringWithFormat:@"%i,%i,%i",turbulence.tileX,turbulence.tileY,turbulence.altitude]];
                
                //find tiles above and below
                int currentTileAltitude = tile.altitude;
                
                // ---------  tiles below --------------------
                if (currentTileAltitude>1) {
                    tile.altitude = currentTileAltitude -1;
                    //get turbulence info at tile
                    Turbulence * turbulence = [[TurbulenceManager sharedManager] getTurbulanceAtTile:tile];
                    
                    //if there is no turbelence at that tile of the turbulence is too old insert blank turbulence
                    if (!turbulence || [[NSDate date] timeIntervalSince1970] - turbulence.timestamp > _cutOffTime) {
                        turbulence = [Turbulence new];
                        turbulence.tileX=tile.x;
                        turbulence.tileY=tile.y;
                        turbulence.altitude = tile.altitude;
                        turbulence.severity = 0;
                        turbulence.timestamp = 0;
                        
                    }
                    
                    [tilesInRigionBelow setObject:turbulence forKey:[NSString stringWithFormat:@"%i,%i,%i",turbulence.tileX,turbulence.tileY,turbulence.altitude]];
                }
                
                // ---------  tiles above --------------------
                if (currentTileAltitude<kAltitude_NumberOfSteps) {
                    tile.altitude = currentTileAltitude +1;
                    //get turbulence info at tile
                    Turbulence * turbulence = [[TurbulenceManager sharedManager] getTurbulanceAtTile:tile];
                    //if there is no turbelence at that tile of the turbulence is too old insert blank turbulence
                    if (!turbulence || [[NSDate date] timeIntervalSince1970] - turbulence.timestamp > _cutOffTime) {
                        turbulence = [Turbulence new];
                        turbulence.tileX=tile.x;
                        turbulence.tileY=tile.y;
                        turbulence.altitude = tile.altitude;
                        turbulence.severity = 0;
                        turbulence.timestamp = 0;
                        
                    }
                    
                    [tilesInRigionAbove setObject:turbulence forKey:[NSString stringWithFormat:@"%i,%i,%i",turbulence.tileX,turbulence.tileY,turbulence.altitude]];
                }
            }
        }
        
    }
    
    
    
    _arrTurbelenceBelow = [tilesInRigionBelow allValues];
    _arrTurbelenceAt = [tilesInRigionAt allValues];
    _arrTurbelenceAbove = [tilesInRigionAbove allValues];
    
    _altBelowAlert = [self getMaxSeverityInAlertZonelevel:_arrTurbelenceBelow];
    _altCurrentAlert = [self getMaxSeverityInAlertZonelevel:_arrTurbelenceAt];
    _altAboveAlert = [self getMaxSeverityInAlertZonelevel:_arrTurbelenceAbove];
});
    
    
}

-(int) getMaxSeverityInAlertZonelevel:(NSArray *) arrAtLevel
{
    int maxSeverity = 0;
    for (Turbulence * turbulence in arrAtLevel) {

        if (turbulence.severity >= kAlertSeverityForAlert) {
            if (turbulence.severity > maxSeverity) {
                maxSeverity = turbulence.severity;
            };
        }
    }
    return maxSeverity;
}

#pragma mark - Alert states
-(void) setState_NoAlert {
    _alertState = ZLAlert_NoAlerts;
    NSLog(@"ZLAlert_NoAlerts");
}

-(void) setState_NewAlert {
    _alertState = ZLAlert_NewAlert;
        NSLog(@"ZLAlert_NewAlert");
}

-(void) setState_NewAlertNoGPS {
    _alertState = ZLAlert_NewAlertNoGPS;
        NSLog(@"ZLAlert_NewAlertNoGPS");
}

-(void) setState_UserAccepted {
    _alertState = ZLAlert_UserAccepted;
        NSLog(@"ZLAlert_UserAccepted");
}

-(void) setState_UserAcceptedNoGPS {
    _alertState = ZLAlert_UserAcceptedNoGPS;
        NSLog(@"ZLAlert_UserAcceptedNoGPS");
}

-(void)alertCycle {
    CLLocation * currentLocation = [[LocationManager sharedManager] getCurrentLocation];

    bool isGoodLocation = [LocationManager sharedManager].isLocationGood ;
    bool isGoodCourse = [LocationManager sharedManager].isHeadingGood;
    
    if (DEBUG_MODE) {
        isGoodCourse = true;
        isGoodLocation = true;
    }

    
    //calculate alert zone @ levels
    if (isGoodCourse && isGoodLocation) {
            [self tilesInAlertAreaWithLocation:currentLocation];
    }


    bool isAlertInZone = (_altAboveAlert + _altCurrentAlert + _altBelowAlert > 0);
    
    //save current alert state
    ZLAlertState oldAlertState = _alertState;
    
    switch (_alertState) {
            
        case ZLAlert_NoAlerts:
            //if there is new alert go to new alert state
            if (isAlertInZone && isGoodCourse && isGoodLocation) {
                [self setState_NewAlert];
            }
            
            break;
        case ZLAlert_NewAlert:
            //if no alerts in zone go to no alert State
            if (!isAlertInZone) [self setState_NoAlert];
            
            //if no gps or course go to New Alert No GPS state
            if (!isGoodCourse || !isGoodLocation) [self setState_NewAlertNoGPS];
            
            //if user accepted go to user accepted state
            if (_isUserAccepted ) {
                _isUserAccepted = false;
                [self setState_UserAccepted];
            }
            
            break;
        case ZLAlert_NewAlertNoGPS:
            //if good gps and good course go back to to New Alert  state
            if (isGoodCourse && isGoodLocation) [self setState_NewAlert];
            
            //if user accepted go to user accepted  NO GPS state
            if (_isUserAccepted ) {
                _isUserAccepted = false;
                [self setState_UserAcceptedNoGPS];
            }
            
            //if user reset go to user accepted  NO alert state
            if (_isUserReset ) {
                _isUserReset = false;
                [self setState_NoAlert];
            }
            break;
        case ZLAlert_UserAccepted:
            //if no alerts in zone go to no alert State
            if (!isAlertInZone) [self setState_NoAlert];
            
            //if no gps or course go to User Accepted No GPS state
            if (!isGoodCourse || !isGoodLocation) [self setState_UserAcceptedNoGPS];
            
            
            break;
        case ZLAlert_UserAcceptedNoGPS:
            //if good gps and good course go back to to User Accepted  state
            if (isGoodCourse && isGoodLocation) [self setState_UserAccepted];
            
            //if user reset go to user accepted  NO alert state
            if (_isUserReset ) {
                _isUserReset = false;
                [self setState_NoAlert];
            }
            
            break;
        default:
            break;
    }
    if (_alertState!=oldAlertState) {
        [_delegate alertStateChanged:_alertState];
    }
}

#pragma mark - user actions
-(void) userAccepted {
    _isUserAccepted = true;
    [self alertCycle];
}
-(void) userReset{
    _isUserReset = true;
    [self alertCycle];
}

-(void) setCutOffTime:(long)timeInterval {
    _cutOffTime = timeInterval;
    [self alertCycle];
}

@end
