//
//  AirportsManager.m
//  TurboMaps
//
//  Created by Ziv Levy on 8/18/15.
//  Copyright (c) 2015 ZivApps. All rights reserved.
//

#import "AirportsManager.h"

@interface AirportsManager()
@property (nonatomic,strong) NSDictionary * airports;
@end


@implementation AirportsManager

+ (AirportsManager *)sharedManager {
    static AirportsManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (id)init {
    if (self = [super init]) {

        
    
        
    }
    return self;
}


#pragma mark - internal functions
-(NSDictionary *) getAirportsDictionary
{
    NSMutableDictionary * airports = [NSMutableDictionary new];
    //open file
    
    //parse line
    
    //add to dictionary
    
    //return
    return airports;
}
@end
