//
//  Flight.h
//  TurboMaps
//
//  Created by Ziv Levy on 8/20/15.
//  Copyright (c) 2015 ZivApps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Airport.h"

@interface Flight : NSObject

@property (nonatomic,strong) NSString * flightNumber;
@property (nonatomic,strong) Airport * originAirport;
@property (nonatomic,strong) Airport * destinationAirport;
@property BOOL isGreatCircleRoute;

@end
