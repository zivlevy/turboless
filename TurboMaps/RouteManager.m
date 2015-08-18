//
//  RouteManager.m
//  TurboMaps
//
//  Created by Ziv Levy on 8/18/15.
//  Copyright (c) 2015 ZivApps. All rights reserved.
//

#import "RouteManager.h"


@interface RouteManager()
@property (nonatomic,strong) NSDictionary * airports;

@end


@implementation RouteManager

+ (RouteManager *)sharedManager {
    static RouteManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (id)init {
    if (self = [super init]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [self readAirportsFile];
        });
        
    }
    return self;
}


#pragma mark - airports
-(void)readAirportsFile
{
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"airports" ofType:@"txt"];
    if (filePath) {
        
        NSString* fileContents = [NSString stringWithContentsOfFile:filePath
                                                           encoding:NSUTF8StringEncoding
                                                              error:nil];
        NSArray *lines =  [fileContents componentsSeparatedByString:@"\n"];
        
        NSMutableDictionary * allAirports = [NSMutableDictionary new];
        
        
        for (NSString * line in lines) {
            
            NSArray *items = [line componentsSeparatedByString:@","];
            Airport * airport = [Airport new];
            airport.name= items[1];
            airport.city = items[2];
            airport.country = items[3];
            airport.symbol =items[4];
            airport.ICAO =items[5];
            airport.latitude =[items[6] doubleValue];
            airport.longitude =[items[7] doubleValue];
            airport.altitude =[items[8] doubleValue];
            
            [allAirports setObject:airport forKey:airport.ICAO];
        }
        self.airports = allAirports;
    }
}

-(NSArray*) getAirportsBySymbols:(NSString *) str
{

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ICAO CONTAINS %@ or symbol CONTAINS %@", str,str];
    NSArray *filtered = [[_airports allValues] filteredArrayUsingPredicate:predicate];
    return filtered;
}

-(Airport *) getAirportByICAO:(NSString *) ICAO
{
    Airport * airport = nil;
    airport = [_airports objectForKey:ICAO];
    return airport;
}



@end

