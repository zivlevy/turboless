//
//  AccelerometerManager.m
//  TurboMaps
//
//  Created by Ziv Levy on 8/22/15.
//  Copyright (c) 2015 ZivApps. All rights reserved.
//

#import "AccelerometerManager.h"
#import <CoreMotion/CoreMotion.h>
#import "Const.h"
#import "TurbuFilter.h"
#import "AccelerometerEvent.h"
#import "LocationManager.h"

@interface AccelerometerManager ()

@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic,strong) TurbuFilter * turboFilter;

@property bool isDeviceInMotion;
@property bool isLocationValid;

@property (nonatomic,strong) NSTimer * timerDeviceInMotionDelay;

@end

@implementation AccelerometerManager
+ (AccelerometerManager *)sharedManager {
    static AccelerometerManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (id)init {
    if (self = [super init]) {
        _turboFilter = [TurbuFilter new];
        
        //register notification observer for Location status
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationStateChanged:) name:kNotification_LocationStatusChanged object:nil];
        [self start];
        
    }
    return self;
}

#pragma mark - accelerometer logic
-(void) locationStateChanged:(NSNotification *) notification
{
    NSNumber * locationStatus = notification.object;
    if ([locationStatus boolValue]){
        _isLocationValid = true;
    } else {
        _isLocationValid=false;
    }
    
    return;
}

-(void) startAccelormeter:(NSNotification *)notification {
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.accelerometerUpdateInterval = 1/100;
    self.motionManager.gyroUpdateInterval = 1/100;
    
    [self accelerometerInit];
    
    // Tell CoreMotion to show the compass calibration HUD when required
    // to provide true north-referenced attitude
    _motionManager.showsDeviceMovementDisplay = YES;
    _motionManager.deviceMotionUpdateInterval = 1.0 / 20.0;
    
    // Attitude that is referenced to true north
    [_motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXTrueNorthZVertical];
    if ([self.motionManager isGyroAvailable])
    {
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        [self.motionManager startGyroUpdatesToQueue:queue withHandler:^(CMGyroData *gyroData, NSError *error) {
            float rotationRate = sqrt(gyroData.rotationRate.x*gyroData.rotationRate.x +gyroData.rotationRate.y*gyroData.rotationRate.y +gyroData.rotationRate.z*gyroData.rotationRate.z);
            if (rotationRate > 0.8) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_DeviceInMotion object:nil];
                    _isDeviceInMotion = true;
                    if (_motionManager.isAccelerometerActive) {
                        [_motionManager stopAccelerometerUpdates];
                    }
                    
                });
            } else {
                if (!_timerDeviceInMotionDelay && _isDeviceInMotion) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_timerDeviceInMotionDelay invalidate];
                        _timerDeviceInMotionDelay = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self
                                                                                   selector:@selector(inMotionDelayEnd:) userInfo:nil repeats:NO];
                    });
                    
                }
                
            }

        }];
    }
    
}

-(void)inMotionDelayEnd:(NSTimer *)timer{
    _timerDeviceInMotionDelay=nil;
    _isDeviceInMotion = false;
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_DeviceInStatic object:nil];
    [self accelerometerInit];
}

#pragma mark - public functions
-(void)start {
    [self startAccelormeter:nil];
}
-(void)stop {
    [self.motionManager stopAccelerometerUpdates];
}

-(void)accelerometerInit
{
    if ([self.motionManager isAccelerometerAvailable])
    {
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        [self.motionManager startAccelerometerUpdatesToQueue:queue withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
            _isRecordingInSession = false;
            AccelerometerEvent * accelerometerEvent = [AccelerometerEvent new];
            accelerometerEvent.x = accelerometerData.acceleration.x;
            accelerometerEvent.y = accelerometerData.acceleration.y;
            accelerometerEvent.z = accelerometerData.acceleration.z;
            accelerometerEvent.g =sqrt(accelerometerEvent.x*accelerometerEvent.x+accelerometerEvent.y*accelerometerEvent.y+accelerometerEvent.z*accelerometerEvent.z);
            accelerometerEvent.timeStamp=[[NSDate date] timeIntervalSince1970];
            accelerometerEvent.timeStampMiliseconds =[[NSDate date] timeIntervalSince1970]*1000;
            accelerometerEvent.location = [[LocationManager sharedManager] getCurrentLocation];
            if (DEBUG_MODE) {
                if (!_isDeviceInMotion ){
                    _isRecordingInSession = true;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_turboFilter proccesInput:accelerometerEvent];
                        [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_IOSAccelerometerDataRecieved object:accelerometerEvent];
                    });
                    
                }
            } else {
                if (!_isDeviceInMotion && _isLocationValid && [[LocationManager sharedManager] getCurrentLocation].altitude * FEET_PER_METER >= kAltitude_Min * 1000) {
                    _isRecordingInSession = true;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_turboFilter proccesInput:accelerometerEvent];
                        [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_IOSAccelerometerDataRecieved object:accelerometerEvent];
                    });
                    
                }
            }
            
            
            
        }];
    } else {
        NSLog(@"not active");
    }
    
}


@end
