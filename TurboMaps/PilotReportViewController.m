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
    [_btnSend setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    switch (_turbulenceLevel) {
        case 1:
            _btnSend.backgroundColor = kColorLight;
            
            break;
        case 2:
            _btnSend.backgroundColor = kColorLightModerate;
            [_btnSend setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
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
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
    
    
    //Check for valid gps fix
    if (![[LocationManager sharedManager] isLocationGood]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"GPS fix is not available. \n Can't send information." message:@"" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    TurbulenceEvent * event = [TurbulenceEvent new];
    
    // find current location
    ZLTile tile = [[LocationManager sharedManager] getCurrentTile];
    event.tileX=tile.x;
    event.tileY=tile.y;
    event.altitude=tile.altitude;
    
    //TODO
    // check for valid altitude
    if (event.altitude <=0 || event.altitude>kAltitude_NumberOfSteps) {
        //        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"GPS fix is not available. \n Can't send information." message:@"" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        //        [alert show];
        //        return;
    }
    event.severity=(int)_turbulenceLevel;
    event.isPilotEvent = YES;
    
    
    event.flightNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"flightNumber"];
    NSDate * now = [NSDate date];
    event.date = now;
    
    
    event.userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"userName"];
    
    [[RecorderManager sharedManager] writeTurbulenceEvent:event];
}



@end
