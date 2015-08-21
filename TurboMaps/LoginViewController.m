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

@property (weak, nonatomic) IBOutlet UITextField *txtUserID;
@property (weak, nonatomic) IBOutlet UITextField *txtPassword;
@property (weak, nonatomic) IBOutlet UIView *viewMainView;



@end
@implementation LoginViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    [Helpers makeRound:(UIView *)_btnLogin borderWidth:1 borderColor:[UIColor whiteColor]];
    [Helpers makeRound:((UIView *)_imageAppIcon) borderWidth:2 borderColor:[UIColor whiteColor]];
    
}

-(void)dealloc{
    
    NSLog(@"dealloc");
}
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSString * build = [[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString *)kCFBundleVersionKey];
    self.lblVersion.text = [NSString stringWithFormat:@"Version %@.%@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"],build];
}
- (IBAction)btnLogin_Clicked:(id)sender {
    
    //check that user name is valid
    if (![self isValidEmpID:_txtUserID.text withAlert:YES]) {
        return;
    }
    [[NSUserDefaults standardUserDefaults] setObject:self.txtUserID.text forKey:@"userName"];
    [self performSegueWithIdentifier:@"segueLoginToMainView" sender:self];
    
}

# pragma mark - Employee ID manager
-(BOOL) isValidEmpID:(NSString *)empID withAlert:(BOOL) withAlert
{
    BOOL isLegalempID = NO;
    if (empID.length >0)
    {
        NSScanner *scanner = [NSScanner scannerWithString:[empID substringFromIndex:1]];
        BOOL  isNumeric = [scanner scanInteger:NULL] && [scanner isAtEnd];
        if (empID.length==7 && [[empID substringToIndex:2] isEqualToString:@"e0"] && isNumeric) {
            isLegalempID=YES;
        }
    }
    if (!isLegalempID && withAlert) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"User ID has an error \n Please try again." message:@"" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [_txtUserID becomeFirstResponder];
        return NO;
    }
    return YES;
}


@end
