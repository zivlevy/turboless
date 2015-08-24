//
//  Turbulence.m
//  TurboMaps
//
//  Created by Ziv Levy on 8/18/15.
//  Copyright (c) 2015 ZivApps. All rights reserved.
//

#import "Turbulence.h"


@implementation Turbulence


-(NSString *) description {
    NSDate * tDate = [NSDate dateWithTimeIntervalSince1970:_timestamp];
    NSString * tSeverity = [NSString stringWithFormat:@"%i",_severity];
    NSString * tAltitude = [NSString stringWithFormat:@"%i",_altitude];
    NSString * tX = [NSString stringWithFormat:@"%i",_tileX];
     NSString * tY = [NSString stringWithFormat:@"%i",_tileY];
    return [NSString stringWithFormat:@"Date:  %@ Altitude: %@ Severity: %@ TileX: %@ TileY: %@ \n",tDate,tAltitude,tSeverity,tX,tY];
}
@end
