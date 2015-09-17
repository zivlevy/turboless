//
//  AlertsManager.m
//  TurboMaps
//
//  Created by Ziv Levy on 9/15/15.
//  Copyright (c) 2015 ZivApps. All rights reserved.
//

#import "AlertsManager.h"
#import "Const.h"
#import "LocationManager.h"
#import "MapUtils.h"
#import "Turbulence.h"
#import "TurbulenceManager.h"




@interface AlertsManager()
@property (nonatomic,strong) NSTimer * timer;
@end


@implementation AlertsManager
+ (AlertsManager *)sharedManager {
    static AlertsManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (id)init {
    if (self = [super init]) {
        //set timer to watch for alerts
        _timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self
                                                selector:@selector(checkAlerts:) userInfo:nil repeats:YES];
    }
    return self;
}

# pragma mark - timer
- (void) checkAlerts:(NSTimer *)incomingTimer
{
    [self tilesInAlertArea];
}


# pragma mark - logic
-(NSArray *) tilesInAlertArea
{
    
    NSMutableDictionary * tilesInRigion = [NSMutableDictionary new];
    
    //current location and course
    CLLocation * currentLocation = [[LocationManager sharedManager] getCurrentLocation];
    bool isAltitudeLeagal = DEBUG_MODE ? true : currentLocation.altitude > kAltitude_Min * FEET_PER_METER ;
    //if we are above min altitude and there is leagal course
    if ( isAltitudeLeagal && currentLocation.course >0) {

        //step every 5 miles to make sure we cover all tiles in range
        for (float i=0; i<kAlertRange; i+=5) {
            //get cordinate
            CLLocationCoordinate2D stepWP = [MapUtils NewLocationFrom:currentLocation.coordinate atDistanceInMiles:i alongBearingInDegrees:325];//currentLocation.course];
            //convert to location
            CLLocation * stepLocation = [[CLLocation alloc] initWithCoordinate:stepWP altitude:currentLocation.altitude horizontalAccuracy:0 verticalAccuracy:0 timestamp:nil];
            //get the tile at that location
            ZLTile tile = [[LocationManager sharedManager] getTileForLocation:stepLocation];
            tile.altitude=15;
            //get turbulence info at tile
            Turbulence * turbulence = [[TurbulenceManager sharedManager] getTurbulanceAtTile:tile];
            //insert tile to collection if above moderate severity
            if (turbulence.severity >0 ) {
                [tilesInRigion setObject:turbulence forKey:[NSString stringWithFormat:@"%i,%i,%i",turbulence.tileX,turbulence.tileY,turbulence.altitude]];
            }
            
            //get the tile above
            if (tile.altitude<kAltitude_NumberOfSteps){
                ZLTile tileAbove = tile;
                tileAbove.altitude=tile.altitude+1;
                
                turbulence = [[TurbulenceManager sharedManager] getTurbulanceAtTile:tileAbove];
                if (turbulence.severity > 2) {
                    [tilesInRigion setObject:turbulence forKey:[NSString stringWithFormat:@"%i,%i,%i",turbulence.tileX,turbulence.tileY,turbulence.altitude]];
                }
            }

            
            //get the tile below
            if (tile.altitude>1){
                ZLTile tileBelow = tile;
                tileBelow.altitude=tile.altitude-1;
                
                turbulence = [[TurbulenceManager sharedManager] getTurbulanceAtTile:tileBelow];
                if (turbulence.severity > 2) {
                    [tilesInRigion setObject:turbulence forKey:[NSString stringWithFormat:@"%i,%i,%i",turbulence.tileX,turbulence.tileY,turbulence.altitude]];
                }
            }
        }
       
    }
    
    //get rigion borders
    

    
    NSArray * result = [tilesInRigion allValues];
//     NSLog(@"%lu", (unsigned long)result.count);
    return result;
}



@end
