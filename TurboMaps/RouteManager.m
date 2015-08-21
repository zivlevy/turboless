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
        [self readAirportsFile];
        
        //init current flight from storage
        _currentFlight = [Flight new];
        NSString * originICAO = [[NSUserDefaults standardUserDefaults] objectForKey:@"originAirport"];
        if (!originICAO) {
            originICAO = @"LLBG";
            [[NSUserDefaults standardUserDefaults] setObject:originICAO forKey:@"originAirport"];
        }
        _currentFlight.originAirport = [self getAirportByICAO:originICAO];
        
        NSString * destinationICAO = [[NSUserDefaults standardUserDefaults] objectForKey:@"destinationAirport"];
        if (!destinationICAO) {
            destinationICAO = @"KJFK";
            [[NSUserDefaults standardUserDefaults] setObject:destinationICAO forKey:@"destinationAirport"];
        }
        _currentFlight.destinationAirport =[self getAirportByICAO:destinationICAO];
        
        _currentFlight.flightNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"flightNumber"];
        
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
    if ([str isEqualToString:@""])
    {
        NSSortDescriptor *ageDescriptor = [[NSSortDescriptor alloc] initWithKey:@"ICAO" ascending:YES];
        NSArray *sortDescriptors = @[ageDescriptor];
        NSArray *sorted = [[_airports allValues] sortedArrayUsingDescriptors:sortDescriptors];
        return sorted;
    }
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ICAO CONTAINS[cd] %@ or symbol CONTAINS[cd] %@ or city CONTAINS[cd] %@", str,str,str];
    NSArray *filtered = [[_airports allValues] filteredArrayUsingPredicate:predicate];
    
    NSSortDescriptor *ageDescriptor = [[NSSortDescriptor alloc] initWithKey:@"ICAO" ascending:YES];
    NSArray *sortDescriptors = @[ageDescriptor];
    NSArray *sorted = [filtered sortedArrayUsingDescriptors:sortDescriptors];
    return sorted;
}

-(NSArray *) getAirports{
    NSArray * arr =[_airports allValues];
    

    
    return arr;
}
-(Airport *) getAirportByICAO:(NSString *) ICAO
{
    Airport * airport = nil;
    airport = [_airports objectForKey:ICAO];
    return airport;
}



@end

