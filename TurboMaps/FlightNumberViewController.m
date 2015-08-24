//
//  FlightNumberViewController.m
//  TurboMaps
//
//  Created by Ziv Levy on 8/23/15.
//  Copyright (c) 2015 ZivApps. All rights reserved.
//

#import "FlightNumberViewController.h"
#import "Helpers.h"
#import "Const.h"

@interface FlightNumberViewController()<UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UIButton *btnSave;
@property (weak, nonatomic) IBOutlet UITextField *txtFlightNumber;

@end
@implementation FlightNumberViewController

-(void) viewDidLoad
{
    [super viewDidLoad];
    [Helpers makeRound:_btnSave borderWidth:1 borderColor:[UIColor whiteColor]];
    self.txtFlightNumber.delegate = self;
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _txtFlightNumber.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"flightNumber"];
    [_txtFlightNumber becomeFirstResponder];
}

- (IBAction)btnSave_clicked:(id)sender {
    //remove leading zero from flight number if it is needed (flight number is 4 digits long)
    if (_txtFlightNumber.text.length ==4 && [[_txtFlightNumber.text substringToIndex:1] isEqualToString:@"0"]) {
        _txtFlightNumber.text = [_txtFlightNumber.text substringFromIndex:1];
    }
    if (_txtFlightNumber.text.length>0 && ( _txtFlightNumber.text.length <3 || _txtFlightNumber.text.length>4)) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Flight Number should be\n3 or 4 digits long" message:@"" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    [[NSUserDefaults standardUserDefaults]setObject:_txtFlightNumber.text forKey:@"flightNumber"];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_FlightNumberChanged object:nil ];
    
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}
#pragma mark - uitext delegate
-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    // allow backspace
    if (!string.length)
    {
        return YES;
    }
    

        if ([string rangeOfCharacterFromSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]].location != NSNotFound)
        {
            return NO;
        }
    
    // verify max length has not been exceeded
    NSString *updatedText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    if (updatedText.length > 4)
    {
        return NO;
    }
    
    
    return YES;
}
@end
