//
//  Helpers.m
//  Turboless
//
//  Created by Ziv Levy on 7/31/15.
//  Copyright (c) 2015 ZivApps. All rights reserved.
//

#import "Helpers.h"


@implementation Helpers

+(void)roundCornersOnView:(UIView *)view onTopLeft:(BOOL)tl topRight:(BOOL)tr bottomLeft:(BOOL)bl bottomRight:(BOOL)br radius:(float)radius {
    
    if (tl || tr || bl || br) {
        UIRectCorner corner = 0; //holds the corner
        //Determine which corner(s) should be changed
        if (tl) {
            corner = corner | UIRectCornerTopLeft;
        }
        if (tr) {
            corner = corner | UIRectCornerTopRight;
        }
        if (bl) {
            corner = corner | UIRectCornerBottomLeft;
        }
        if (br) {
            corner = corner | UIRectCornerBottomRight;
        }
        
        UIView *roundedView = view;
        UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:roundedView.bounds byRoundingCorners:corner cornerRadii:CGSizeMake(radius, radius)];
        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        maskLayer.frame = roundedView.bounds;
        maskLayer.path = maskPath.CGPath;
        roundedView.layer.mask = maskLayer;
    }
    
}
+(void) makeRoundCorners:(UIView *) view radius:(int) radius borderWidth:(int)borderWidth borderColor:(UIColor *) borderColor
{
    
    view.layer.cornerRadius = radius;
    view.layer.borderWidth = borderWidth;
    view.layer.borderColor = borderColor.CGColor;
    
}
+(void) makeRound:(UIView *) button borderWidth:(int)borderWidth borderColor:(UIColor *) borderColor
{
    button.layer.cornerRadius = button.bounds.size.height/2;
    button.layer.borderWidth = borderWidth;
    button.layer.borderColor = borderColor.CGColor;
}
+(UIColor *) r:(int)r g:(int)g b:(int)b alpha:(float)alpha
{
    return [UIColor colorWithRed:(float)r/255.0 green:(float)g/255.0 blue:(float)b/255.0 alpha:alpha];
}

#pragma mark - file system
+ (NSString *)applicationDocumentsDirectory {
    NSURL * url =  [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                   inDomains:NSUserDomainMask] lastObject];
    return url.path;
}

+(NSString *) getFilePathInDocuments:(NSString *) fileName
{
    return [[Helpers applicationDocumentsDirectory] stringByAppendingPathComponent:fileName];
}

+(NSString *) getGMTTimeString:(NSDate *) dateValue withFormat:(NSString *) format
{
    NSDateFormatter* df_local = [[NSDateFormatter alloc] init];
    //[df_local setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]]; //ODO add Daytime saving support
    [df_local setDateFormat:format];
    NSString * formatedDate = [df_local stringFromDate:dateValue];
    
    return formatedDate;
}
@end
