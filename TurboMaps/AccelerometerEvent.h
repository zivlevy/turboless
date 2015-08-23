//
//  AccelerometerEvent.h
//  TurboMaps
//
//  Created by Ziv Levy on 8/22/15.
//  Copyright (c) 2015 ZivApps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
@interface AccelerometerEvent : NSObject
@property double x;
@property double y;
@property double z;
@property double g;
@property long timeStamp;
@property (nonatomic,strong) CLLocation * location;

@end
