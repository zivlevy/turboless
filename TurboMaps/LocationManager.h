//
//  LocationManager.h
//  TurboMaps
//
//  Created by Ziv Levy on 8/17/15.
//  Copyright (c) 2015 ZivApps. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct {
    int x;
    int y;
    int altitude;
} ZLTile;

@interface LocationManager : NSObject

@property bool isLocationGood;
+ (LocationManager *)sharedManager;
-(ZLTile)getCurrentTile;
@end
