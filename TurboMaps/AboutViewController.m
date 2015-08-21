//
//  AboutViewController.m
//  TurboMaps
//
//  Created by Ziv Levy on 8/17/15.
//  Copyright (c) 2015 ZivApps. All rights reserved.
//

#import "AboutViewController.h"
#import "Helpers.h" 
#import "RecorderManager.h"


@interface AboutViewController ()
@property (weak, nonatomic) IBOutlet UILabel *lblVersion;
@property (weak, nonatomic) IBOutlet UIImageView *imageAppIcon;
@property (weak, nonatomic) IBOutlet UIButton *btnLogout;

@end

@implementation AboutViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    [Helpers makeRound:((UIView *)_imageAppIcon) borderWidth:2 borderColor:[UIColor whiteColor]];
    [Helpers makeRound:((UIView *)_btnLogout) borderWidth:1 borderColor:[UIColor whiteColor]];

}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSString * build = [[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString *)kCFBundleVersionKey];
    self.lblVersion.text = [NSString stringWithFormat:@"Version %@.%@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"],build];
    if (![[RecorderManager sharedManager] isReachable]) {
        self.btnLogout.hidden=YES;
    } else {
       self.btnLogout.hidden=NO;
    }
}
-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
}
- (IBAction)btnLogout_Clicked:(id)sender {
    [self.delegate logout];

}


@end
