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

@interface PilotReportViewController ()
@property (weak, nonatomic) IBOutlet UIButton *btnSend;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segTime;

@end

@implementation PilotReportViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [Helpers makeRound:_btnSend borderWidth:1 borderColor:[UIColor whiteColor]];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [_segTime setSelectedSegmentIndex:0];
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
- (IBAction)btnSend_Clicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}



@end
