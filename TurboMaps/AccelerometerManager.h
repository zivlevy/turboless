//
//  AccelerometerManager.h
//  TurboMaps
//
//  Created by Ziv Levy on 8/22/15.
//  Copyright (c) 2015 ZivApps. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AccelerometerManager : NSObject

+ (AccelerometerManager *)sharedManager;

-(void)start;
-(void)stop;
@end
