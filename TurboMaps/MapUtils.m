//
//  MapUtils.m
//  TurboMaps
//
//  Created by Ziv Levy on 8/10/15.
//  Copyright (c) 2015 ZivApps. All rights reserved.
//

#import "MapUtils.h"

@implementation MapUtils

+(CLLocationCoordinate2D) getCenterCoordinatesForTilePathForZoom:(NSString *) tilePathForZoom{
    int  zoomLevelForAnnotation;
    switch ([tilePathForZoom substringFromIndex:(tilePathForZoom.length-2)].integerValue) {
        case 11:
            zoomLevelForAnnotation = 11;
            break;
        case 10:
            zoomLevelForAnnotation =10;
            break;
        case 9:
            zoomLevelForAnnotation =9;
            break;
        case 8:
            zoomLevelForAnnotation =8;
            break;
        default:
            break;
    }

    //set x,y,z
    double tile_x = [tilePathForZoom substringToIndex:(tilePathForZoom.length -2 )/2].doubleValue +0.5;

    NSRange yTileRange;
    yTileRange.location = (tilePathForZoom.length -2 )/2;
    yTileRange.length = (tilePathForZoom.length -2 )/2;
    
    double tile_y = [tilePathForZoom substringWithRange:yTileRange].doubleValue +0.5;
    
    NSRange zoomRange;
    zoomRange.location = (tilePathForZoom.length-2);
    zoomRange.length = 2;
    
    double zoom = [tilePathForZoom substringWithRange:zoomRange].doubleValue;
    CLLocationCoordinate2D p ;
    double n = M_PI - ((2.0 * M_PI * tile_y) / pow(2.0, zoom));
    
    p.longitude = (float)((tile_x / pow(2.0, zoom) * 360.0) - 180.0);
    p.latitude = (float)(180.0 /M_PI * atan(sinh(n)));
    
    return p;
    
    
}

+(NSString*) transformWorldCoordinateToTilePathForZoom:(int)zoom fromLon:(double) lon  fromLat:(double) lat
{
    
    int padding = [NSString stringWithFormat:@"%i",(int)pow(2,zoom)].length;
    int tileX = (int)(floor((lon + 180.0) / 360.0 * pow(2.0, zoom)));
    int tileY = (int)(floor((1.0 - log( tan(lat * M_PI/180.0) + 1.0 / cos(lat * M_PI/180.0)) / M_PI) / 2.0 * pow(2.0, zoom)));
    NSString * path = [NSString stringWithFormat:@"%@%@%@",[self padInt:tileX padTo:padding], [self padInt:tileY padTo:padding],[self padInt:zoom padTo:2]];
    return path;
}

#pragma mark - helpers
+(NSString *) padInt:(int) number padTo:(int)padTo {
    NSString * original = [NSString stringWithFormat:@"%i",number];
    if (original.length<4){
        for (int i=(int) original.length;i< padTo; i++) {
            original = [NSString stringWithFormat:@"0%@",original];
        }
    }
    return original;
}
@end
