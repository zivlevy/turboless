//
//  TurbulenceEvent.h
//  TurboMaps
//
//  Created by Ziv Levy on 8/23/15.
//  Copyright (c) 2015 ZivApps. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TurbulenceEvent : NSObject
@property int tileX;
@property int tileY;
@property int altitude;
@property int severity;
@property bool isPilotEvent;
@property (nonatomic,strong) NSString * flightNumber;
@property (nonatomic,strong) NSDate * date;
@property (nonatomic,strong) NSString * userId;
@end
