//
//  DebugManager.h
//  TurboMaps
//
//  Created by Ziv Levy on 8/24/15.
//  Copyright (c) 2015 ZivApps. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DebugManagerDelegate <NSObject>

@optional
-(void)debugManagerSaveSuccess;
-(void)debugManagerSaveFail;
-(void)debugManagerSaveProgress:(float)precent;

@end

@interface DebugManager : NSObject
+ (DebugManager *)sharedManager;
@property (nonatomic, weak) id <DebugManagerDelegate> delegate;

@property bool isRecording;

-(void)startRecording:(NSString*) fileName;
-(void)endRecording;

-(NSArray *) getDebugFileList;
//-(void)removeDebugFile;
-(void)sendDataFile:(NSString *) fileName;

@end
