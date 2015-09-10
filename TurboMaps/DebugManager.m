//
//  DebugManager.m
//  TurboMaps
//
//  Created by Ziv Levy on 8/24/15.
//  Copyright (c) 2015 ZivApps. All rights reserved.
//

#import "DebugManager.h"
#import "AccelerometerEvent.h"
#import "Const.h"
#import "ZipArchive.h"
#import "Helpers.h"
#import "AFNetworking.h"


@interface PathWithModDate : NSObject
@property (strong) NSString *path;
@property (strong) NSDate *modDate;
@end

@implementation PathWithModDate
@end


@interface DebugManager()
@property (nonatomic,strong) NSString * dataFileName;
@property (nonatomic,strong) NSString * turbulenceFileName;
@property (nonatomic,strong) NSString * gpsFileName;
@property (nonatomic,strong) NSString * locationChangeFileName;
@end

@implementation DebugManager

+ (DebugManager *)sharedManager {
    static DebugManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];

    });
    return sharedMyManager;
}

- (id)init {
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accelerometerEvent:) name:kNotification_IOSAccelerometerDataRecieved object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(turbulenceWriteToFile:) name:kNotification_TurbulenceEventWrittenToFile object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationStatusChanged:) name:kNotification_LocationStatusChanged object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newGpsLocation:) name:kNotification_NewGPSLocation object:nil];

        
    }
    return self;
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}
#pragma mark - notifications

-(void) accelerometerEvent:(NSNotification *) notification {
    if (!_isRecording) {
        return;
    }
    
    AccelerometerEvent * event = notification.object;
    
    NSString * content = [NSString stringWithFormat:@"%ld,%f,%f,%f,%f\n",event.timeStampMiliseconds,event.x,event.y,event.z,event.g];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:self.dataFileName])
    {
        [content writeToFile:self.dataFileName
                  atomically:NO
                    encoding:NSStringEncodingConversionAllowLossy
                       error:nil];
    }
    else
    {
        NSFileHandle *myHandle = [NSFileHandle fileHandleForWritingAtPath:self.dataFileName];
        [myHandle seekToEndOfFile];
        [myHandle writeData:[content dataUsingEncoding:NSUTF8StringEncoding]];
    }
}

-(void) turbulenceWriteToFile:(NSNotification *) notification {
    if (!_isRecording) {
        return;
    }
    
    NSString * content = notification.object;

    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:_turbulenceFileName])
    {
        [content writeToFile:_turbulenceFileName
                  atomically:NO
                    encoding:NSStringEncodingConversionAllowLossy
                       error:nil];
    }
    else
    {
        NSFileHandle *myHandle = [NSFileHandle fileHandleForWritingAtPath:_turbulenceFileName];
        [myHandle seekToEndOfFile];
        [myHandle writeData:[content dataUsingEncoding:NSUTF8StringEncoding]];
    }
}

-(void) locationStatusChanged:(NSNotification *) notification {
    if (!_isRecording) {
        return;
    }
    
    NSNumber *  data = notification.object;

    long timestamp  = [[NSDate date] timeIntervalSince1970] *1000;
    
    NSString * content = [NSString stringWithFormat:@"%ld,%@,%i\n",timestamp,[Helpers  getGMTTimeString:[NSDate date] withFormat:@"dd/MM hh:mm"], [data boolValue]];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:_locationChangeFileName])
    {
        [content writeToFile:_locationChangeFileName
                  atomically:NO
                    encoding:NSStringEncodingConversionAllowLossy
                       error:nil];
    }
    else
    {
        NSFileHandle *myHandle = [NSFileHandle fileHandleForWritingAtPath:_locationChangeFileName];
        [myHandle seekToEndOfFile];
        [myHandle writeData:[content dataUsingEncoding:NSUTF8StringEncoding]];
    }
}
-(void) newGpsLocation:(NSNotification *) notification {
    if (!_isRecording) {
        return;
    }
    
    CLLocation *  newLocation = notification.object;
    
    NSString * content = [NSString stringWithFormat:@"%@,%f,%f,%f,%f,%f\n", newLocation.timestamp, newLocation.coordinate.latitude,newLocation.coordinate.longitude,newLocation.altitude, newLocation.horizontalAccuracy,newLocation.verticalAccuracy];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:_gpsFileName])
    {
        [content writeToFile:_gpsFileName
                  atomically:NO
                    encoding:NSStringEncodingConversionAllowLossy
                       error:nil];
    }
    else
    {
        NSFileHandle *myHandle = [NSFileHandle fileHandleForWritingAtPath:_gpsFileName];
        [myHandle seekToEndOfFile];
        [myHandle writeData:[content dataUsingEncoding:NSUTF8StringEncoding]];
    }
}


#pragma mark - public functions
-(void)startRecording:(NSString*) sessionName {
    _isRecording=true;

    //set file names
    NSArray *paths = NSSearchPathForDirectoriesInDomains
    (NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    //create directory for the recorded files
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString * dirName =[NSString stringWithFormat:@"%@/debugFiles/%@",
                         documentsDirectory, sessionName];
    [fileManager createDirectoryAtPath:dirName withIntermediateDirectories:YES attributes:nil error:nil];
    
    //make a file name to write the data to using the documents directory:
    _dataFileName = [NSString stringWithFormat:@"%@/debugFiles/%@/flightData.txt",
                     documentsDirectory, sessionName];
    _turbulenceFileName = [NSString stringWithFormat:@"%@/debugFiles/%@/turbulence.txt",
                     documentsDirectory, sessionName];
    _locationChangeFileName= [NSString stringWithFormat:@"%@/debugFiles/%@/locationChanges.txt",
                   documentsDirectory, sessionName];
    _gpsFileName=[NSString stringWithFormat:@"%@/debugFiles/%@/gpsData.txt",
                  documentsDirectory, sessionName];
}

-(void)endRecording {
    _isRecording=false;
}

-(NSArray *)getDebugFileList {

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory =[NSString stringWithFormat:@"%@/debugFiles", [paths objectAtIndex:0]];
    
    NSArray *allPaths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:nil ];
    
    NSMutableArray *sortedPaths = [NSMutableArray new];
    for (NSString *path in allPaths) {
        NSString *fullPath = [documentsDirectory stringByAppendingPathComponent:path];
        
        NSDictionary *attr = [NSFileManager.defaultManager attributesOfItemAtPath:fullPath error:nil];
        NSDate *modDate = [attr objectForKey:NSFileModificationDate];
        
        PathWithModDate *pathWithDate = [[PathWithModDate alloc] init];
        pathWithDate.path = path;
        pathWithDate.modDate = modDate;
        [sortedPaths addObject:pathWithDate];
    }
    
    [sortedPaths sortUsingComparator:^(PathWithModDate *path1, PathWithModDate *path2) {
        // Descending (most recently modified first)
        return [path2.modDate compare:path1.modDate];
    }];
    NSMutableArray * resultsArray = [NSMutableArray new];
    for (PathWithModDate * path in sortedPaths) {
        [resultsArray addObject:path.path];
    }
    return resultsArray;


}

-(void)sendDataFile:(NSString *) fileName {

    //create directory for the recorded files
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *dirName = [Helpers getFilePathInDocuments:@"zipFiles"] ;
    [fileManager createDirectoryAtPath:dirName withIntermediateDirectories:YES attributes:nil error:nil];
    
    NSString * zipFileName = [NSString stringWithFormat:@"%@/%@.zip",
                     dirName, fileName];
    
    dirName = [Helpers getFilePathInDocuments:@"debugFiles"] ;
    NSString * directoryToZip = [NSString stringWithFormat:@"%@/%@",dirName,fileName] ;
    [Main createZipFileAtPath:zipFileName
      withContentsOfDirectory:directoryToZip];
    
    //send to server

    NSString * postURL = [NSString stringWithFormat:@"%@/raw-data",kBaseURL];

    AFHTTPRequestSerializer *serializer = [AFHTTPRequestSerializer serializer];
    
    //add token
    NSString * token = [[NSUserDefaults standardUserDefaults] objectForKey:@"token"];
    [serializer setValue:token forHTTPHeaderField:@"x-access-token"];
    NSMutableURLRequest *request =
    [serializer multipartFormRequestWithMethod:@"POST" URLString:postURL
                                    parameters:nil
                     constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                         [formData appendPartWithFileData:[[NSFileManager defaultManager] contentsAtPath:zipFileName]
                                                     name:@"test"
                                                 fileName:zipFileName
                                                 mimeType:@"application/zip"];
                     } error:nil];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
    
    AFHTTPRequestOperation *operation =
    [manager HTTPRequestOperationWithRequest:request
                                     success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                         
                                         
                                         //delete original and zip files
                                         [fileManager removeItemAtPath:zipFileName error:nil];
                                         [fileManager removeItemAtPath:directoryToZip error:nil];
                                         //update delegate
                                         [_delegate debugManagerSaveSuccess];
                                     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {

                                         NSInteger statusCode = operation.response.statusCode;
                                         if(statusCode == 401) {
                                             //tokwn ia invalid - logout
                                             [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_InvalidToken object:nil];
                                         }
                                         [_delegate debugManagerSaveFail];
                                     }];
    

    [operation setUploadProgressBlock:^(NSUInteger __unused bytesWritten,
                                        long long totalBytesWritten,
                                        long long totalBytesExpectedToWrite) {
        //update delgate
        [_delegate debugManagerSaveProgress:totalBytesWritten/totalBytesExpectedToWrite ];
    }];
    
    [operation start];
    
    
}
@end
