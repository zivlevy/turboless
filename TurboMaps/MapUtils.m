//
//  MapUtils.m
//  TurboMaps
//
//  Created by Ziv Levy on 8/10/15.
//  Copyright (c) 2015 ZivApps. All rights reserved.
//

#import "MapUtils.h"

#define kPi 3.141592653589793

CGFloat DEG2RAD(CGFloat degrees) { return degrees * M_PI / 180; };
CGFloat RAD2DEG(CGFloat radians) { return radians * 180 / M_PI; };

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
    
    int padding = (int)[NSString stringWithFormat:@"%i",(int)pow(2,zoom)].length;
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


+ (CLLocationCoordinate2D) NewLocationFrom:(CLLocationCoordinate2D)startingPoint
                         atDistanceInMiles:(float)distanceInMiles
                     alongBearingInDegrees:(double)bearingInDegrees {
    
    double lat1 = DEG2RAD(startingPoint.latitude);
    double lon1 = DEG2RAD(startingPoint.longitude);
    
    double a = 6378137, b = 6356752.3142, f = 1/298.257223563;  // WGS-84 ellipsiod
    double s = distanceInMiles * 1.61 * 1000;  // Convert to meters
    double alpha1 = DEG2RAD(bearingInDegrees);
    double sinAlpha1 = sin(alpha1);
    double cosAlpha1 = cos(alpha1);
    
    double tanU1 = (1 - f) * tan(lat1);
    double cosU1 = 1 / sqrt((1 + tanU1 * tanU1));
    double sinU1 = tanU1 * cosU1;
    double sigma1 = atan2(tanU1, cosAlpha1);
    double sinAlpha = cosU1 * sinAlpha1;
    double cosSqAlpha = 1 - sinAlpha * sinAlpha;
    double uSq = cosSqAlpha * (a * a - b * b) / (b * b);
    double A = 1 + uSq / 16384 * (4096 + uSq * (-768 + uSq * (320 - 175 * uSq)));
    double B = uSq / 1024 * (256 + uSq * (-128 + uSq * (74 - 47 * uSq)));
    
    double sigma = s / (b * A);
    double sigmaP = 2 * kPi;
    
    double cos2SigmaM = 0.0;
    double sinSigma = 0.0;
    double cosSigma = 0.0;
    
    while (fabs(sigma - sigmaP) > 1e-12) {
        cos2SigmaM = cos(2 * sigma1 + sigma);
        sinSigma = sin(sigma);
        cosSigma = cos(sigma);
        double deltaSigma = B * sinSigma * (cos2SigmaM + B / 4 * (cosSigma * (-1 + 2 * cos2SigmaM * cos2SigmaM) - B / 6 * cos2SigmaM * (-3 + 4 * sinSigma * sinSigma) * (-3 + 4 * cos2SigmaM * cos2SigmaM)));
        sigmaP = sigma;
        sigma = s / (b * A) + deltaSigma;
    }
    
    double tmp = sinU1 * sinSigma - cosU1 * cosSigma * cosAlpha1;
    double lat2 = atan2(sinU1 * cosSigma + cosU1 * sinSigma * cosAlpha1, (1 - f) * sqrt(sinAlpha * sinAlpha + tmp * tmp));
    double lambda = atan2(sinSigma * sinAlpha1, cosU1 * cosSigma - sinU1 * sinSigma * cosAlpha1);
    double C = f / 16 * cosSqAlpha * (4 + f * (4 - 3 * cosSqAlpha));
    double L = lambda - (1 - C) * f * sinAlpha * (sigma + C * sinSigma * (cos2SigmaM + C * cosSigma * (-1 + 2 * cos2SigmaM * cos2SigmaM)));
    
    double lon2 = lon1 + L;
    
    // Create a new CLLocationCoordinate2D for this point
    CLLocationCoordinate2D edgePoint = CLLocationCoordinate2DMake(RAD2DEG(lat2), RAD2DEG(lon2));
    
    return edgePoint;
}
@end
