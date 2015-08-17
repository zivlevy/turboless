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
    
    [super viewDidLoad];
}

-(void) viewWillAppear:(BOOL)animated
{
       _slider.value = [[UIScreen mainScreen] brightness]; 
}


- (IBAction)sliderChanged:(UISlider *)sender {
        [[UIScreen mainScreen] setBrightness:sender.value];
}

@end
