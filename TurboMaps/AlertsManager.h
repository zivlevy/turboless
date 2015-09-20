//
//  AlertsManager.h
//  TurboMaps
//
//  Created by Ziv Levy on 9/15/15.
//  Copyright (c) 2015 ZivApps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

typedef NS_ENUM(NSInteger, ZLAlertState) {
    ZLAlert_NoAlerts          = 0,
    ZLAlert_NewAlert     = 1,
    ZLAlert_NewAlertNoGPS = 2,
    ZLAlert_UserAccepted = 3,
    ZLAlert_UserAcceptedNoGPS = 4,
};

@protocol AlertsManagerDelegate <NSObject>

@optional
-(void)alertStateChanged:(ZLAlertState) newState;

@end

@interface AlertsManager : NSObject

@property ZLAlertState alertState;

+ (AlertsManager *)sharedManager;
@property (nonatomic, weak) id <AlertsManagerDelegate> delegate;
@property int altBelowAlert;
@property int altCurrentAlert;
@property int altAboveAlert;

-(void) userAccepted;
-(void) userReset;
-(void) setCutOffTime:(long)timeInterval;
-(void) tilesInAlertAreaWithLocation:(CLLocation *) location;

@end
