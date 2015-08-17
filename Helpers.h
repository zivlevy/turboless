//
//  Helpers.h
//  Turboless
//
//  Created by Ziv Levy on 7/31/15.
//  Copyright (c) 2015 ZivApps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

@interface Helpers : NSObject

+(void)roundCornersOnView:(UIView *)view onTopLeft:(BOOL)tl topRight:(BOOL)tr bottomLeft:(BOOL)bl bottomRight:(BOOL)br radius:(float)radius;
// makeRoundCorners: gets a UIView and adds radius to corners
+(void) makeRoundCorners:(UIView *) view radius:(int) radius borderWidth:(int)borderWidth borderColor:(UIColor *) borderColor;

// makeRound: gets a UIButton and makes it round
+(void) makeRound:(UIButton *) button borderWidth:(int)borderWidth borderColor:(UIColor *) borderColor;

+(UIColor *) r:(int)r g:(int)g b:(int)b alpha:(float)alpha ;

@end
