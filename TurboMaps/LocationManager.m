//
//  LocationManager.m
//  TurboMaps
//
//  Created by Ziv Levy on 8/17/15.
//  Copyright (c) 2015 ZivApps. All rights reserved.
//

#import "LocationManager.h"

#import "Const.h"


@interface LocationManager()<CLLocationManagerDelegate>
@property(nonatomic)CLLocationManager *locationManager;
@property (nonatomic,strong) CLLocation *  currentLocation;
@property (nonatomic,strong) NSTimer * timer;

@property int debugAlltitude;
@property float debugCoordinateDelta;
@end


@implementation LocationManager

+ (LocationManager *)sharedManager {
    static LocationManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (id)init {
    if (self = [super init]) {
        //location

        _locationManager =[[CLLocationManager alloc]init];
        [_locationManager requestAlwaysAuthorization];
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        
        [self.locationManager startUpdatingLocation];
        //debug GPS
        _debugAlltitude  = 21000;
        //set timer to watch for good location
        _timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self
                                               selector:@selector(checkGoodLocation:) userInfo:nil repeats:YES];
    }
    return self;
}

# pragma mark - timer
- (void) checkGoodLocation:(NSTimer *)incomingTimer
{
    
    // location
    if ([[NSDate date] timeIntervalSinceDate:_currentLocation.timestamp] > 2  || _currentLocation.horizontalAccuracy > 5000 || _currentLocation.verticalAccuracy > 2000) {
        if (_isLocationGood) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_LocationStatusChanged object:[NSNumber numberWithBool:NO]];
        }
        self.isLocationGood = NO;
    } else {
        if (!_isLocationGood) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_LocationStatusChanged object:[NSNumber numberWithBool:YES]];
            
        }
        self.isLocationGood = YES;
    }
    
    //heading
    if ( _currentLocation.course <0) {
        if (_isHeadingGood) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_HeadingStatusChanged object:[NSNumber numberWithBool:NO]];
        }
        _isHeadingGood = NO;
    } else {
        if (!_isHeadingGood) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_HeadingStatusChanged object:[NSNumber numberWithBool:YES]];
            
        }
        _isHeadingGood = YES;
    }
    
}

#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"didFailWithError: %@", error);
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    _currentLocation = newLocation;
    //////////////// Debug ///////////////////////////////////////////////////////////////////////
    if (DEBUG_MODE) {
        _debugCoordinateDelta +=0.1;
        CLLocationCoordinate2D location;
        location=newLocation.coordinate;
//        location.latitude = location.latitude + _debugCoordinateDelta;
//        location.longitude = 127.0;
        
        CLLocation *sampleLocation = [[CLLocation alloc] initWithCoordinate: location
                                                                   altitude:_debugAlltitude /FEET_PER_METER
                                                         horizontalAccuracy:100
                                                           verticalAccuracy:100 
                                                                  timestamp:[NSDate date]];
        _currentLocation = sampleLocation;
        _debugAlltitude-=200;
        if (_debugAlltitude >40000) _debugAlltitude = 40000;
        if (_debugAlltitude <1000) _debugAlltitude = 1000;
        NSLog(@"%i",_debugAlltitude);
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_NewGPSLocation object:_currentLocation];
    
}

-(ZLTile)getCurrentTile
{
    double lat = _currentLocation.coordinate.latitude;
    double lon = _currentLocation.coordinate.longitude;
    ZLTile tile;
    int zoom = 11;
    int tileX = (int)(floor((lon + 180.0) / 360.0 * pow(2.0, zoom)));
    int tileY = (int)(floor((1.0 - log( tan(lat * M_PI/180.0) + 1.0 / cos(lat * M_PI/180.0)) / M_PI) / 2.0 * pow(2.0, zoom)));
    
    //calculate altitude slot
    float alt = _currentLocation.altitude * FEET_PER_METER / 1000;
    int altitude =ceil( (alt -kAltitude_Min) / kAltitude_Step );
    tile.x = tileX;
    tile.y=tileY;
    tile.altitude = altitude;
    return tile;
}

-(CLLocation *) getCurrentLocation
{
    return _currentLocation;
}

-(ZLTile) getTileForLocation:(CLLocation *)location
{
    double lat = location.coordinate.latitude;
    double lon = location.coordinate.longitude;
    ZLTile tile;
    int zoom = 11;
    int tileX = (int)(floor((lon + 180.0) / 360.0 * pow(2.0, zoom)));
    int tileY = (int)(floor((1.0 - log( tan(lat * M_PI/180.0) + 1.0 / cos(lat * M_PI/180.0)) / M_PI) / 2.0 * pow(2.0, zoom)));
    
    //calculate altitude slot
    int alt = location.altitude * FEET_PER_METER / 1000;
    int altitude = (alt -kAltitude_Min) / kAltitude_Step ;
    tile.x = tileX;
    tile.y=tileY;
    tile.altitude = altitude;
    return tile;
}
@end
