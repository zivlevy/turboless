//
//  BrightnessViewController.m
//  TurboMaps
//
//  Created by Ziv Levy on 8/17/15.
//  Copyright (c) 2015 ZivApps. All rights reserved.
//

#import "BrightnessViewController.h"

@interface BrightnessViewController ()
@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (weak, nonatomic) IBOutlet UISwitch *swcKeepDisplayOn;

@end

@implementation BrightnessViewController

- (void)viewDidLoad
{
    
    _slider.minimumValue = 0.f;
    _slider.maximumValue = 1.0f;
    _slider.value = [[UIScreen mainScreen] brightness];
    UIImage *sliderThumb = [UIImage imageNamed:@"slider20.png"];
    [_slider setThumbImage:sliderThumb forState:UIControlStateNormal];
    [_slider setThumbImage:sliderThumb forState:UIControlStateHighlighted];
    
    [self.swcKeepDisplayOn setOn:[[NSUserDefaults standardUserDefaults] boolForKey :@"keepDisplayOn"]];
    [super viewDidLoad];
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
       _slider.value = [[UIScreen mainScreen] brightness]; 
}


- (IBAction)sliderChanged:(UISlider *)sender {
        [[UIScreen mainScreen] setBrightness:sender.value];
}

- (IBAction)swcKeepDisplayOn_Changed:(UISwitch *)sender{
    if ([sender isOn]) {
        [UIApplication sharedApplication].idleTimerDisabled = YES;
    } else {
        [UIApplication sharedApplication].idleTimerDisabled = NO;
    }
    [[NSUserDefaults standardUserDefaults] setBool:[sender isOn] forKey:@"keepDisplayOn"];
}
@end
