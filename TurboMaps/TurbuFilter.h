//
//  TurbuFilter.h
//  
//
//  Created by Ziv Levy on 8/22/15.
//  Copyright (c) 2015 ZivApps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AccelerometerEvent.h"

@interface TurbuFilter : NSObject
-(void)proccesInput:(AccelerometerEvent *) event;
@end
