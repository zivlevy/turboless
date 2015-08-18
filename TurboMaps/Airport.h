//
//  Airport.h
//  TurboMaps
//
//  Created by Ziv Levy on 8/18/15.
//  Copyright (c) 2015 ZivApps. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Airport : NSObject
@property (nonatomic,strong) NSString * name;
@property (nonatomic,strong) NSString * country;
@property (nonatomic,strong) NSString * city;
@property (nonatomic,strong) NSString * symbol;
@property (nonatomic,strong) NSString * ICAO;
@property double latitude;
@property double longitude;
@property double altitude;
@end
