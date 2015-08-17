//
//  PilotReportViewController.m
//  TurboMaps
//
//  Created by Ziv Levy on 8/17/15.
//  Copyright (c) 2015 ZivApps. All rights reserved.
//

#import "PilotReportViewController.h"
#import "Helpers.h"
#import "Const.h"
#import "RecorderManager.h"
#import "LocationManager.h"

@interface PilotReportViewController ()
@property (weak, nonatomic) IBOutlet UIButton *btnSend;

@end

@implementation PilotReportViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [Helpers makeRound:_btnSend borderWidth:1 borderColor:[UIColor whiteColor]];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    switch (_turbulenceLevel) {
        case 1:
            _btnSend.backgroundColor = kColorLight;
            break;
        case 2:
            _btnSend.backgroundColor = kColorLightModerate;
            break;
        case 3:
            _btnSend.backgroundColor = kColorModerate;
            break;
        case 4:
            _btnSend.backgroundColor = kColorSevere;
            break;
        case 5:
            _btnSend.backgroundColor = kColorExtream;
            break;
        default:
            break;
    }
}
- (IBAction)btnSend_Clicked:(UIButton *)sender {
    ZLTurbulenceEvent event;
    
    // find current location
    ZLTile tile = [[LocationManager sharedManager] getCurrentTile];
    event.tileX=tile.x;
    event.tileY=tile.y;
    event.altitude=tile.altitude;
    
    event.severity=(int)_turbulenceLevel;
    event.isPilotEvent = YES;
    
    //TODO
    event.flightNumber = @"0";
    NSDate * now = [NSDate date];
    event.date = now;
    
    //TODO
    event.userId = @"e098288";
    
    [[RecorderManager sharedManager] writeTurbulenceEvent:event];
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}



@end
