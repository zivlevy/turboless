//
//  RecorderManager.m
//  TurboMaps
//
//  Created by Ziv Levy on 8/17/15.
//  Copyright (c) 2015 ZivApps. All rights reserved.
//

#import "RecorderManager.h"
#import "Const.h"
#import "AFNetworking.h"
#import "AccelerometerManager.h"
#import "LocationManager.h"

@interface RecorderManager ()
@property bool isReachableState;
@property bool isFileTransferInProgress;
@property (nonatomic,strong)NSTimer * timerTrySendData;

@property (nonatomic,strong) NSMutableDictionary * dicVisitedTiles;
@property ZLTile currentTile;

@end

@implementation RecorderManager

+ (RecorderManager *)sharedManager {
    static RecorderManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (id)init {
    if (self = [super init]) {
        //start monitoring reachability
        [[AFNetworkReachabilityManager sharedManager] startMonitoring];
        
        [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            
            switch (status) {
                case AFNetworkReachabilityStatusNotReachable:
                    NSLog(@"No Internet Connection");
                    _isReachableState = NO;
                    break;
                case AFNetworkReachabilityStatusReachableViaWiFi:
                    NSLog(@"WIFI");
                    
                    _isReachableState = YES;
                    break;
                case AFNetworkReachabilityStatusReachableViaWWAN:
                    NSLog(@"3G");
                    _isReachableState = YES;
                    break;
                default:
                    NSLog(@"Unkown network status");
                    _isReachableState = NO;
                    break;
                    
                    
            }
            if (_isReachableState) {
                [self tryTransferFile];
            }
        }];
        //set noftidications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationChanged:) name:kNotification_NewGPSLocation object:nil];
        
        //set timer to try and send data
        _timerTrySendData = [NSTimer scheduledTimerWithTimeInterval:20.0 target:self
                                                selector:@selector(sendDataTimer:) userInfo:nil repeats:YES];
        
        //init Visited Tiles Dictionary
        _dicVisitedTiles = [NSMutableDictionary new];
        _currentTile.x=0;
        _currentTile.y=0;
        _currentTile.altitude = 0;
    }
    return self;
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}
#pragma mark - event handeling

-(void)writeTurbulenceEvent:(TurbulenceEvent *) event
{
    //check that data is valid
    bool isSeverityValid = (event.severity >=0 && event.severity <=5);
    bool isAltitudeValid = event.altitude >0 &&  event.altitude <=kAltitude_NumberOfSteps;
    bool isTileXValid = event.tileX >=0 && event.tileX <=2047;
    bool isTileYValid = event.tileY >=0 && event.tileY <=2047;
    
    if (! (isSeverityValid && isAltitudeValid && isTileXValid && isTileYValid)) {
        return;
    }
    
    //set content
    NSString * content = [NSString stringWithFormat:@"%i,%i,%i,%i,%i,%@,%lld,%@\n",event.tileX,event.tileY,event.altitude,event.severity,event.isPilotEvent,event.flightNumber,(long long)[event.date timeIntervalSince1970],event.userId];
    
    //set file name
    NSArray *paths = NSSearchPathForDirectoriesInDomains
    (NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString * fileName = [NSString stringWithFormat:@"%@/%@",
                     documentsDirectory, @"fileData.txt"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:fileName])
    {
        [content writeToFile:fileName
                  atomically:NO
                    encoding:NSStringEncodingConversionAllowLossy
                       error:nil];
    }
    else
    {
        NSFileHandle *myHandle = [NSFileHandle fileHandleForWritingAtPath:fileName];
        [myHandle seekToEndOfFile];
        [myHandle writeData:[content dataUsingEncoding:NSUTF8StringEncoding]];
    }

    //add the event to visited dictionary
    [_dicVisitedTiles setObject:event forKey:[NSString stringWithFormat:@"%i,%i,%i",event.tileX,event.tileY  ,event.altitude]];
    
    //notify that the event was added
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_TurbulenceEventWrittenToFile object:content userInfo:nil];
    
}


#pragma mark - send data
-(void)sendDataTimer: (NSTimer *) timer
{
    if (!_isFileTransferInProgress) {
        [self tryTransferFile];
    }
}

-(void)tryTransferFile
{
    //if not reachable
    if (!_isReachableState) {
        return;
    }
    
    if (_isFileTransferInProgress) {
        return;
    }
    _isFileTransferInProgress = true;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePathSrc = [documentsDirectory stringByAppendingPathComponent:@"deliveryFile.txt"];
    //if deliveryFile.txt exists send it
    if([fileManager fileExistsAtPath:filePathSrc])
    {
        [self sendFile];
    } else {
        //if fileData.txt exists copy it
        filePathSrc = [documentsDirectory stringByAppendingPathComponent:@"fileData.txt"];
        if([fileManager fileExistsAtPath:filePathSrc]){
            [self renameFileWithName:@"fileData.txt" toName:@"deliveryFile.txt"];
            _isFileTransferInProgress=NO;
            [self tryTransferFile];
        } else {
            _isFileTransferInProgress=NO;
        }
    }
    
    
}

-(void)sendFile
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePathSrc = [documentsDirectory stringByAppendingPathComponent:@"deliveryFile.txt"];
    //prepare JSON
    NSMutableArray * eventsArray = [NSMutableArray new];
    
    
    NSString *contents = [NSString stringWithContentsOfFile:filePathSrc encoding:NSASCIIStringEncoding error:nil];
    NSArray *lines = [contents componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\r\n"]];
    for (NSString* line in lines) {
        if (line.length) {
            NSArray *eventData = [line componentsSeparatedByString:@","];
            NSMutableDictionary * eventDictionary = [NSMutableDictionary new];
            [eventDictionary setObject:eventData[0]  forKey:@"tileX"];
            [eventDictionary setObject:eventData[1]  forKey:@"tileY"];
            int alt = [eventData[2] intValue];
//            if (alt <0) alt = 0; //TODO remove relese
            NSString * strAlt = [NSString stringWithFormat:@"%i",alt]; //TODO change
            [eventDictionary setObject:strAlt  forKey:@"alt"];
            [eventDictionary setObject:eventData[3]  forKey:@"sev"];
            [eventDictionary setObject:eventData[4]  forKey:@"pEv"];
            [eventDictionary setObject:eventData[5]  forKey:@"fNum"];
            [eventDictionary setObject:eventData[6]  forKey:@"ts"];
            [eventDictionary setObject:eventData[7]  forKey:@"repId"];
            [eventsArray addObject:eventDictionary];
            
        }
    }
    NSDictionary * JSON = [NSDictionary dictionaryWithObject:eventsArray forKey:@"events"];

    //send
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    NSMutableSet  * theset = [[NSMutableSet alloc]initWithSet:manager.responseSerializer.acceptableContentTypes];

    [theset addObject:@"text/plain"];
    manager.responseSerializer.acceptableContentTypes = [theset copy];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    NSString * token = [[NSUserDefaults standardUserDefaults] objectForKey:@"token"];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"x-access-token"];
    
    NSString * strURL = [NSString stringWithFormat:@"%@/reports",kBaseURL];
    [manager POST:strURL parameters:JSON
          success:^(AFHTTPRequestOperation *operation, id responseObject)
    {
        [fileManager removeItemAtPath:filePathSrc error:nil];
        _isFileTransferInProgress=NO;
        [self tryTransferFile];
    }
          failure:
     ^(AFHTTPRequestOperation *operation, NSError *error) {
         NSLog(@"Error: %@", error);
         //if not ok - try again on next timer interval
         _isFileTransferInProgress=NO;
         NSInteger statusCode = operation.response.statusCode;
         if(statusCode == 401) {
             //tokwn ia invalid - logout
             [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_InvalidToken object:nil];
         }

     }];
    


    

}


#pragma mark - file handeling helpers
- (void)renameFileWithName:(NSString *)srcName toName:(NSString *)dstName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePathSrc = [documentsDirectory stringByAppendingPathComponent:srcName];
    NSString *filePathDst = [documentsDirectory stringByAppendingPathComponent:dstName];
    NSFileManager *manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:filePathSrc]) {
        NSError *error = nil;
        [manager moveItemAtPath:filePathSrc toPath:filePathDst error:&error];
        if (error) {
            NSLog(@"There is an Error: %@", error);
        }
    } else {
        NSLog(@"File %@ doesn't exists", srcName);
    }
}

- (void)deleteFileWithName:(NSString *)fileName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    // Have the absolute path of file named fileName by joining the document path with fileName, separated by path separator.
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:fileName];
    
    NSFileManager *manager = [NSFileManager defaultManager];
    // Need to check if the to be deleted file exists.
    if ([manager fileExistsAtPath:filePath]) {
        NSError *error = nil;
        // This function also returnsYES if the item was removed successfully or if path was nil.
        // Returns NO if an error occurred.
        [manager removeItemAtPath:filePath error:&error];
        if (error) {
            NSLog(@"There is an Error: %@", error);
        }
    } else {
        NSLog(@"File %@ doesn't exists", fileName);
    }
}


#pragma mark - public helpers
-(bool)isReachable{
    return _isReachableState;
}


#pragma mark - notification handlers
-(void)locationChanged:(NSNotification*)notification {
    
    if (![AccelerometerManager sharedManager].isRecordingInSession) {
        ZLTile tile = [[LocationManager sharedManager] getCurrentTile];
        if (tile.x!=_currentTile.x || tile.y!= _currentTile.y || tile.altitude!=_currentTile.altitude) {
           //we moved to new tile
            
            //check if this is the first tile
            if (_currentTile.x==0 && _currentTile.y==0 && _currentTile.altitude==0) {
                _currentTile=tile;
                return;
            }
            
            if (![_dicVisitedTiles objectForKey:[NSString stringWithFormat:@"%i,%i,%i",_currentTile.x,_currentTile.y,_currentTile.altitude]]){
                
                //no events in this tile so report Empty tile
                TurbulenceEvent * event = [TurbulenceEvent new];
                event.tileX=_currentTile.x;
                event.tileY=_currentTile.y;
                event.altitude=_currentTile.altitude;
                event.severity = 0;
                event.isPilotEvent = 0;
                event.flightNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"flightNumber"];
                NSDate * now = [NSDate date];
                event.date = now;
                event.userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"userName"];
                [self writeTurbulenceEvent:event ];
                

                
            }
            _currentTile=tile;
            
        }
    }
    
    
}


@end
