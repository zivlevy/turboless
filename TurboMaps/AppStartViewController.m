//
//  AppStartViewController.m
//  TurboMaps
//
//  Created by Ziv Levy on 8/18/15.
//  Copyright (c) 2015 ZivApps. All rights reserved.
//

#import "AppStartViewController.h"
#import "Const.h"

@interface AppStartViewController ()

@end

@implementation AppStartViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}



-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSString * userName=[[NSUserDefaults standardUserDefaults] objectForKey:@"token"];
    
    if (!userName) {
        [self performSegueWithIdentifier:@"segueLogin" sender:self];
    } else {
        [self performSegueWithIdentifier:@"segueMainView" sender:self];
    }
    
    
    
    
    
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(IBAction)prepareForUnwind:(UIStoryboardSegue *)segue {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"token"];
}



@end