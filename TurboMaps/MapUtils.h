//
//  MapUtils.h
//  TurboMaps
//
//  Created by Ziv Levy on 8/10/15.
//  Copyright (c) 2015 ZivApps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Mapbox.h"

@interface MapUtils : NSObject

+(CLLocationCoordinate2D) getCenterCoordinatesForTilePathForZoom:(NSString *) tilePathForZoom;
+(NSString*) transformWorldCoordinateToTilePathForZoom:(int)zoom fromLon:(double) lon  fromLat:(double) lat;

+(NSString *) padInt:(int) number padTo:(int)padTo;
@end
