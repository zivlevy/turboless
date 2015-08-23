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

#import "DDFileReader.h"
@interface testViewController()
@property (nonatomic,strong)TurbuFilter * turbufilter;

@end
@implementation testViewController
-(void)viewDidLoad  {
    _turbufilter = [TurbuFilter new];
}

- (IBAction)btnTestFile_Clicked:(id)sender {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    
    NSString* filePath = @"flightData";
    NSString* fileRoot = [[NSBundle mainBundle]
                          pathForResource:filePath ofType:@"txt"];
    DDFileReader * reader = [[DDFileReader alloc] initWithFilePath:fileRoot];
    NSString * line = nil;
    long i = 0;
    while ((line = [reader readLine])) {
        i++;
        //        NSLog(@"%li",i);
        NSArray* singleStrs =
        [line componentsSeparatedByCharactersInSet:
         [NSCharacterSet characterSetWithCharactersInString:@","]];

        AccelerometerEvent *event = [AccelerometerEvent new];
        event.g= [singleStrs[12] doubleValue];
        event.timeStamp =(long)[singleStrs[1] longLongValue];
        [_turbufilter proccesInput:event];
    }    // first, separate by new lin
        });
}

@end
