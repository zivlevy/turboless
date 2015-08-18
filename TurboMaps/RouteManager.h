//
//  RouteManager.h
//  TurboMaps
//
//  Created by Ziv Levy on 8/18/15.
//  Copyright (c) 2015 ZivApps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Airport.h"
@interface RouteManager : NSObject
+ (RouteManager *)sharedManager;

//airports
-(NSArray*) getAirportsBySymbols:(NSString *) str;
-(Airport *) getAirportByICAO:(NSString *) ICAO;

@end
