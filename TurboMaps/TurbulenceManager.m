//
//  TurbulenceManager.m
//  TurboMaps
//
//  Created by Ziv Levy on 8/18/15.
//  Copyright (c) 2015 ZivApps. All rights reserved.
//

#import "TurbulenceManager.h"
#import "AFNetworking.h"
#import "Const.h"
#import "Helpers.h"
#import "Turbulence.h"

@interface TurbulenceManager()
//turbulenceLevels holds dictionary of tiles for each altitude level
@property (nonatomic,strong) NSMutableArray * turbulenceLevels;
@property long lastServerUpdate;
@property (nonatomic,strong) NSTimer * timerServerUpdate;
@property bool isDownloadInProgress;

@end

@implementation TurbulenceManager
+ (TurbulenceManager *)sharedManager {
    static TurbulenceManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (id)init {
    if (self = [super init]) {
        
        [self buildTurbulenceFromFile];
        _isDownloadInProgress = false;
        [self getTurbulenceFromServer];
        //set timer to watch for good location
        _timerServerUpdate = [NSTimer scheduledTimerWithTimeInterval:4*5 target:self
                                                         selector:@selector(checkServerUpdates:) userInfo:nil repeats:YES];

        
    }
    return self;
}

# pragma mark - timer
- (void) checkServerUpdates:(NSTimer *)incomingTimer
{
    [self getTurbulenceFromServer];
}

#pragma mark - import turbulence data

-(void) getTurbulenceFromServer
{
    if (_isDownloadInProgress) {
        return;
    }
    _isDownloadInProgress =true;
    NSLog(@"Getting Turbulence from server");
    //get operation
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    
    NSString * strURL = [NSString stringWithFormat:@"%@/turbulence",kBaseURL];
    [manager GET:strURL parameters:nil
         success:^(AFHTTPRequestOperation *operation, id responseObject)
     {

         NSString *archiveFileName = [Helpers getFilePathInDocuments:@"turbulence.dat"];
         
         

         NSDictionary * dic = responseObject;
         
         long  lastServerUpdate = [[dic objectForKey:@"serverUpdate"] longValue];
         long currentTurbulenceUpdate = [self getSavedServerUpdateSince1970];
         //check if the data is new
         if ( currentTurbulenceUpdate < lastServerUpdate) {
             
             //save data to file
             bool isFileWritten = [dic writeToFile:archiveFileName atomically:YES];
             
             if (!isFileWritten) {
                 NSLog(@"coudn't save Turbulence file");
             } else {
                 [self buildTurbulenceFromFile ];
                 [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_turbulenceServerNewFile object:nil];
             }
             _isDownloadInProgress=false;
             
         }
         _isDownloadInProgress=false;
     }
         failure:
     ^(AFHTTPRequestOperation *operation, NSError *error) {
         NSLog(@"Error: %@", error);
         _isDownloadInProgress=false;
     }];

}

-(void) buildTurbulenceFromFile
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSString *archiveFileName = [Helpers getFilePathInDocuments:@"turbulence.dat"];
        NSDictionary * dic = [NSDictionary dictionaryWithContentsOfFile:archiveFileName];
        //get last server update
        long lastServerUpdate = [[dic objectForKey:@"serverUpdate"] longValue];
        [self setSavedServerUpdate:lastServerUpdate];
        NSArray * arrTurbulence = [dic objectForKey:@"turbulence"];
        // reset old data
        if (arrTurbulence.count >0) {
            //init turbulenceLevel array
            _turbulenceLevels = [NSMutableArray new];
            for (int i=0; i<=kAltitude_NumberOfSteps; i++) {
                NSMutableDictionary * levelDic = [NSMutableDictionary new];
                [_turbulenceLevels addObject:levelDic];
            }

        }
        //build turbulence data
        for (NSDictionary  * turbuDic in arrTurbulence) {
            Turbulence * turbulence = [Turbulence new];
            turbulence.tileX = [[turbuDic objectForKey:@"tileX"] intValue];
            turbulence.tileY = [[turbuDic objectForKey:@"tileY"] intValue];
            turbulence.altitude = [[turbuDic objectForKey:@"alt"] intValue];
            turbulence.severity = [[turbuDic objectForKey:@"sev"] intValue];
            turbulence.timestamp = [[turbuDic objectForKey:@"ts"] longValue];
            
            if (turbulence.altitude < kAltitude_Min) turbulence.altitude = 1; //TODO change this protection to not allow ileagal info to penetrate
            //add to relevant dictionary by x,y key
            NSMutableDictionary * levelDic = _turbulenceLevels[turbulence.altitude-1];
            [levelDic setObject:turbulence forKey:[NSString stringWithFormat:@"%i,%i",turbulence.tileX,turbulence.tileY]];
            
        }
    });
}


-(void) setSavedServerUpdate:(long) serverUpdate
{
    self.lastServerUpdate = serverUpdate;
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%li",serverUpdate] forKey:@"turbulenceLastUpdate"];
}

#pragma mark - public
-(NSDictionary *) getTurbulanceDictionaryArLevel:(int)level
{
    if (level <=kAltitude_NumberOfSteps) {
        return _turbulenceLevels[level];
    } else {
        return nil;
    }
}

-(long long) getSavedServerUpdateSince1970
{
    NSString * lastUpdate = [[NSUserDefaults standardUserDefaults] objectForKey:@"turbulenceLastUpdate"];
    if (lastUpdate) {
        return [lastUpdate longLongValue];
    } else {
        return 0;
    }
    
}
@end
