//
//  LoginViewController.m
//  TurboMaps
//
//  Created by Ziv Levy on 8/18/15.
//  Copyright (c) 2015 ZivApps. All rights reserved.
//

#import "LoginViewController.h"
#import "Helpers.h"

@interface LoginViewController()

@property (weak, nonatomic) IBOutlet UIButton *btnLogin;
@property (weak, nonatomic) IBOutlet UIImageView *imageAppIcon;
@property (weak, nonatomic) IBOutlet UILabel *lblVersion;


@end
@implementation LoginViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    [Helpers makeRound:(UIView *)_btnLogin borderWidth:1 borderColor:[UIColor whiteColor]];
    [Helpers makeRound:((UIView *)_imageAppIcon) borderWidth:2 borderColor:[UIColor whiteColor]];
}
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSString * build = [[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString *)kCFBundleVersionKey];
    self.lblVersion.text = [NSString stringWithFormat:@"Version %@.%@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"],build];
}
- (IBAction)btnLogin_Clicked:(id)sender {
    
    [self performSegueWithIdentifier:@"segueLoginToMainView" sender:self];
    
}
@end
