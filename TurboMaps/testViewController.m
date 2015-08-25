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
#import "DebugManager.h"
#import "Const.h"
#import "Helpers.h"

@interface testViewController()<DebugManagerDelegate,UITableViewDelegate,UITableViewDataSource>
@property (nonatomic,strong)TurbuFilter * turbufilter;
@property (nonatomic,strong) NSArray * fileList;
@property (nonatomic,strong) NSString * fileName;
@property (weak, nonatomic) IBOutlet UITextField *txtFlightName;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *btnStartRecording;
@property (weak, nonatomic) IBOutlet UILabel *lblFlightName;
@property (weak, nonatomic) IBOutlet UILabel *lblSendingToServer;
@end
@implementation testViewController
-(void)viewDidLoad  {
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    
    //init btn
    [Helpers makeRound:_btnStartRecording borderWidth:1 borderColor:[UIColor whiteColor]];
}

-(void)viewWillAppear:(BOOL)animated
{
    if ([DebugManager sharedManager].isRecording) {
        [self inRecordState];
    } else {
        [self inNormalState];
    }
    self.fileList = [[DebugManager sharedManager] getDebugFileList];
    [self.tableView reloadData];
    
}




- (IBAction)btnStartRecording_Clicked:(UIButton *)sender {
    if ([DebugManager sharedManager].isRecording) {
        [[DebugManager sharedManager] endRecording];
        //update display
        self.fileList = [[DebugManager sharedManager] getDebugFileList];
        [self.tableView reloadData];
        [self inNormalState];
        return;
    }
    if ([_txtFlightName.text isEqualToString: @""] || !_txtFlightName.text) {
        // alert user
        //report
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Please enter flight number of flight name." message:@"" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }

    
    NSString * userName = [[NSUserDefaults standardUserDefaults] objectForKey:@"userName"];
    NSString * fileName = [NSString stringWithFormat:@"%@_%@_%@",_txtFlightName.text,userName,[Helpers getGMTTimeString:[NSDate date] withFormat:@"ddMMhhmm" ]];
    [[DebugManager sharedManager] startRecording:fileName];
        [self inRecordState];
}



#pragma mark - table view delegates

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.fileList.count;
}

//-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    return 200;
//}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    cell.textLabel.text = [self.fileList objectAtIndex:indexPath.row];
    
    return cell;
    
}


// Override to support conditional editing of the table view.
// This only needs to be implemented if you are going to be returning NO
// for some items. By default, all items are editable.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return YES if you want the specified item to be editable.
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //add code here for when you hit delete
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *documentsPath =[NSString stringWithFormat:@"%@/%@",[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0],@"debugFiles"];
        
        NSString *filePath = [documentsPath stringByAppendingPathComponent:[self.fileList objectAtIndex:indexPath.row]];
        NSError *error;
        BOOL success = [fileManager removeItemAtPath:filePath error:&error];
        if (success) {
            
            self.fileList = [[DebugManager sharedManager]getDebugFileList];
            [self.tableView reloadData];
        }
        else
        {
            NSLog(@"Could not delete file -:%@ ",[error localizedDescription]);
        }
        
    }
}

- (IBAction)btnSaveToServer_Clicked:(UIButton *)sender {
    [self inSendState];
    NSString * filePath;
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    if (indexPath != nil)
    {
        filePath = [self.fileList objectAtIndex:indexPath.row];
        
        [DebugManager sharedManager].delegate = self;
        [[DebugManager sharedManager] sendDataFile:filePath];
    }
    
}
-(NSString *) getFilePathByRow:(NSInteger) row {
    
    NSString *documentsPath =[NSString stringWithFormat:@"%@/%@",[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0],@"debugFiles"];
    
    NSString *filePath = [documentsPath stringByAppendingPathComponent:[self.fileList objectAtIndex:row]];
    return  filePath;
};

#pragma mark - debug manager delegate
-(void)debugManagerSaveSuccess{
    NSLog(@"download good");
    //report
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Upload completed succesfully." message:@"" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    _txtFlightName.text = @"";
    self.fileList = [[DebugManager sharedManager]getDebugFileList];
    [self.tableView reloadData];
    [self inNormalState];
}

-(void) debugManagerSaveFail {
    //report
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Couldn't upload.\nTry again later." message:@"" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    [self inNormalState];
    NSLog(@"download failed");
}

-(void)debugManagerSaveProgress:(float)precent  {
    NSLog(@"download progress %f",precent);
    _lblSendingToServer.text =[NSString stringWithFormat:@"Uploading %i%% ,please wait.",(int)precent*100];
}

#pragma mark - state
-(void)inRecordState {
    _txtFlightName.hidden = true;
    _tableView.hidden = true;
    _lblFlightName.hidden = true;
    [_btnStartRecording  setTitle:@"Stop Recording" forState:UIControlStateNormal];
    _btnStartRecording.tintColor = [UIColor redColor];
     _lblSendingToServer.hidden = true;
}

-(void) inNormalState {
    _txtFlightName.hidden = false;
    _tableView.hidden = false;
    _lblFlightName.hidden = false;
    _btnStartRecording.hidden=false;
    [_btnStartRecording  setTitle:@"Start Recording" forState:UIControlStateNormal];
    _btnStartRecording.tintColor = [UIColor whiteColor];
     _lblSendingToServer.hidden = true;
}

-(void) inSendState {
    _txtFlightName.hidden = true;
    _tableView.hidden = true;
    _lblFlightName.hidden = true;
    _btnStartRecording.hidden = true;
    _lblSendingToServer.hidden = false;

}
@end
