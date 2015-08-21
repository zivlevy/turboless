//
//  AirportSearchViewController.h
//  TurboMaps
//
//  Created by Ziv Levy on 8/19/15.
//  Copyright (c) 2015 ZivApps. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Airport.h"


@protocol AirportSearchDelegate <NSObject>

@optional
- (void)airportSelected:(Airport *) airport toTargetControl:(NSString *) targetControl;

@end

@interface AirportSearchViewController : UIViewController
@property (nonatomic, weak) id <AirportSearchDelegate> delegate;
@property (nonatomic,strong) NSString * inputAirportICAO;
@property (nonatomic,strong) NSString * taragetControl;

@end
