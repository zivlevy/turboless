//
//  LocationManager.h
//  TurboMaps
//
//  Created by Ziv Levy on 8/17/15.
//  Copyright (c) 2015 ZivApps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "Const.h"

@interface LocationManager : NSObject

@property bool isLocationGood;
@property bool isHeadingGood;

+ (LocationManager *)sharedManager;
-(ZLTile)getCurrentTile;
-(CLLocation *) getCurrentLocation;
-(ZLTile) getTileForLocation:(CLLocation *)location;
@end
