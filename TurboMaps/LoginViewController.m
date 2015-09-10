//
//  LoginViewController.m
//  TurboMaps
//
//  Created by Ziv Levy on 8/18/15.
//  Copyright (c) 2015 ZivApps. All rights reserved.
//

#import "LoginViewController.h"
#import "Helpers.h"
#import "AFNetworking.h"
#import "Const.h"

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
    //call login
    
    //send
    NSString * strURL = [NSString stringWithFormat:@"%@/login",kBaseURL];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters = @{@"username": _txtUserID.text,@"password":_txtPassword.text};
    [manager POST:strURL parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        NSDictionary * dict = operation.responseObject;
        NSString *isDebug = [dict objectForKey:@"isDebug"];
        bool debagger = [isDebug boolValue];
        if (isDebug && debagger) {
            [[NSUserDefaults standardUserDefaults] setObject:[dict objectForKey:@"isDebug"] forKey:@"isDebug"];
        } else {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"isDebug"];
            
        }
        NSString *token = [dict objectForKey:@"token"];
        if (token) {
            [[NSUserDefaults standardUserDefaults] setObject:[dict objectForKey:@"token"] forKey:@"token"];
            [self performSegueWithIdentifier:@"segueLoginToMainView" sender:self];
        } else {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"token"];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Login failed" message:@"Try again later." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }



    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSInteger statusCode = operation.response.statusCode;
        if(statusCode == 401) {
            //tokwn ia invalid - logout
            NSDictionary * dict = operation.responseObject;
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[dict objectForKey:@"message"]  message:@"" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Couldn't connect to the server.\n Try again later."  message:@"" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }



        return;
    }];
    

    
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
