//
//  RecorderManager.h
//  TurboMaps
//
//  Created by Ziv Levy on 8/17/15.
//  Copyright (c) 2015 ZivApps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LocationManager.h"
typedef struct {
    int tileX;
    int tileY;
    int altitude;
    int severity;
    bool isPilotEvent;
    __unsafe_unretained NSString * flightNumber;
    __unsafe_unretained NSDate * date;
    __unsafe_unretained NSString * userId;
    
} ZLTurbulenceEvent;

@interface RecorderManager : NSObject
+ (RecorderManager *)sharedManager;
-(void)writeTurbulenceEvent:(ZLTurbulenceEvent) event;
-(bool)isReachable;
@end
