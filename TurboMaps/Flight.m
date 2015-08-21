//
//  Flight.m
//  TurboMaps
//
//  Created by Ziv Levy on 8/20/15.
//  Copyright (c) 2015 ZivApps. All rights reserved.
//

#import "Flight.h"

@implementation Flight

-(void)setOriginAirport:(Airport *)originAirport
{
    [[NSUserDefaults standardUserDefaults] setObject:originAirport.ICAO forKey:@"originAirport"];
    _originAirport=originAirport;
}

-(void)setDestinationAirport:(Airport *)destinationAirport
{
    [[NSUserDefaults standardUserDefaults] setObject:destinationAirport.ICAO forKey:@"destinationAirport"];
    _destinationAirport=destinationAirport;
}

-(void) setFlightNumber:(NSString *)flightNumber
{
    [[NSUserDefaults standardUserDefaults] setObject:flightNumber forKey:@"flightNumber"];
    _flightNumber=flightNumber;
    
}
@end
