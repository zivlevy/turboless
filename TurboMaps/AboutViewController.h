//
//  AboutViewController.h
//  TurboMaps
//
//  Created by Ziv Levy on 8/17/15.
//  Copyright (c) 2015 ZivApps. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol AboutViewDelegate <NSObject>

@optional
- (void)logout;

@end

@interface AboutViewController : UIViewController
@property (nonatomic, weak) id <AboutViewDelegate> delegate;


@end
