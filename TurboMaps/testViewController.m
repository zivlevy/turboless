//
//  testViewController.m
//  TurboMaps
//
//  Created by Ziv Levy on 8/22/15.
//  Copyright (c) 2015 ZivApps. All rights reserved.
//

#import "testViewController.h"
#import "TurbuFilter.h"
#import "AccelerometerEvent.h"

@interface testViewController()
@property (nonatomic,strong)TurbuFilter * turbufilter;

@end
@implementation testViewController
-(void)viewDidLoad  {
    [super viewDidLoad];
    _turbufilter = [TurbuFilter new];
}

- (IBAction)btnTestFile_Clicked:(id)sender {
    
}

@end
