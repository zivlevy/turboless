//
//  InitViewController.m
//  TurboMaps
//
//  Created by Ziv Levy on 8/9/15.
//  Copyright (c) 2015 ZivApps. All rights reserved.
//

#import "InitViewController.h"
#import "Mapbox.h"
#import "YLProgressBar.h"
#import "MapUtils.h"
#import "Helpers.h"
#import "Const.h"
#import "BrightnessViewController.h"
#import "PilotReportViewController.h"
#import "AboutViewController.h"

//managers
#import "LocationManager.h"
#import "RecorderManager.h"



@interface InitViewController ()<RMTileCacheBackgroundDelegate,RMMapViewDelegate,UIPickerViewDataSource,UIPickerViewDelegate>
@property (nonatomic,strong) RMMapView * map;



//right menu bar
@property (weak, nonatomic) IBOutlet UIView *viewRightMenu;

@property (weak, nonatomic) IBOutlet UIPickerView *pickerAltitude;

//top bar
@property (weak, nonatomic) IBOutlet UIToolbar *navBar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *GPSSignal;


//left menu bar
@property (weak, nonatomic) IBOutlet UIView *viewLeftMenu;

// ** btn report
@property (weak, nonatomic) IBOutlet UIButton *btnReport_light;
@property (weak, nonatomic) IBOutlet UIButton *btnReport_lightModerate;
@property (weak, nonatomic) IBOutlet UIButton *btnReport_moderate;
@property (weak, nonatomic) IBOutlet UIButton *btnReport_severe;
@property (weak, nonatomic) IBOutlet UIButton *btnReport_Extreme;


//mapHolder view
@property (weak, nonatomic) IBOutlet UIView *viewMapHolder;

//download view
@property (weak, nonatomic) IBOutlet UIView *viewDownload;
@property (weak, nonatomic) IBOutlet YLProgressBar *progressBar;
@property float count; //how many tiles were downloaded
@property float noTilesToDownload;

//holds the current altitude layer to be displayed
@property int selectedAltitudeLayer;

//the tiles by altitude level each cell in the array holds a level starting at 10
@property (nonatomic,strong) NSMutableArray * tileData;



//legend
@property (weak, nonatomic) IBOutlet UILabel *lblLegendLight;
@property (weak, nonatomic) IBOutlet UILabel *lblLegentLightModerate;
@property (weak, nonatomic) IBOutlet UILabel *lblLegentModerate;
@property (weak, nonatomic) IBOutlet UILabel *lblLegentSevere;
@property (weak, nonatomic) IBOutlet UILabel *lblLegentExtream;
@property (weak, nonatomic) IBOutlet UILabel *lblGpsSignal;

//Popovers
@property (nonatomic, strong) BrightnessViewController *brightnessController;
@property (nonatomic, strong) UIPopoverController *brightnessPopover;

@property (nonatomic,strong) PilotReportViewController * pilotReportController;
@property (nonatomic,strong) UIPopoverController * pilotReportPopover;

@property (nonatomic,strong) AboutViewController * aboutViewController;
@property (nonatomic,strong) UIPopoverController * aboutPopover;

//timers
@property (nonatomic,strong) NSTimer * timerGpsSignal;
@end

@implementation InitViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    // init location manager
    [LocationManager sharedManager];
    
    //init recorder manager
    [RecorderManager sharedManager];
    
    //set timer to watch for good location
    _timerGpsSignal = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self
                                            selector:@selector(checkGoodLocation:) userInfo:nil repeats:YES];


    ///////////
    [[RMConfiguration sharedInstance] setAccessToken:@"pk.eyJ1IjoianVzdGluIiwiYSI6IlpDbUJLSUEifQ.4mG8vhelFMju6HpIY-Hi5A"];

    //Download progress bar init
    [Helpers roundCornersOnView:_viewDownload onTopLeft:YES topRight:YES bottomLeft:YES bottomRight:YES radius:8.0];
    _progressBar.progress =0.0;
    
    
    // topbar init
    _navBar.clipsToBounds=YES;
    //menu bars init
    [Helpers roundCornersOnView:_viewRightMenu onTopLeft:YES topRight:NO bottomLeft:YES bottomRight:NO radius:12.0];
    [Helpers roundCornersOnView:_viewLeftMenu onTopLeft:NO topRight:YES bottomLeft:NO bottomRight:YES radius:12.0];
    
    _btnReport_light.backgroundColor = kColorLight;
    _btnReport_lightModerate.backgroundColor = kColorLightModerate;
    _btnReport_moderate.backgroundColor = kColorModerate;
    _btnReport_severe.backgroundColor = kColorSevere;
    _btnReport_Extreme.backgroundColor = kColorExtream;
    
    [Helpers makeRound:_btnReport_light borderWidth:1 borderColor:[UIColor whiteColor]];
    [Helpers makeRound:_btnReport_lightModerate borderWidth:1 borderColor:[UIColor whiteColor]];
    [Helpers makeRound:_btnReport_moderate borderWidth:1 borderColor:[UIColor whiteColor]];
    [Helpers makeRound:_btnReport_severe borderWidth:1 borderColor:[UIColor whiteColor]];
    [Helpers makeRound:_btnReport_Extreme borderWidth:1 borderColor:[UIColor whiteColor]];
    
    //legend init
    _lblLegendLight.backgroundColor = kColorLight;
    _lblLegentLightModerate.backgroundColor = kColorLightModerate;
    _lblLegentModerate.backgroundColor = kColorModerate;
    _lblLegentSevere.backgroundColor = kColorSevere;
    _lblLegentExtream.backgroundColor = kColorExtream;
    
    //gps signal init
    [Helpers makeRound:((UIView *)_lblGpsSignal) borderWidth:1.0 borderColor:[UIColor clearColor]];
    
    //tile Data array init
    self.tileData = [NSMutableArray new];
    for (int i=0;i<=kAltitude_NumberOfSteps;i++){
        [self.tileData addObject:[NSMutableArray new]];
   
    NSMutableArray * arr = self.tileData[i];
    for (int i=0;i<5000;i++){
        int x= arc4random_uniform(500) + 800;
        int y= arc4random_uniform(400) + 500;
        int value= arc4random_uniform(6);
        NSString * tileInfo = [NSString stringWithFormat:@"%@,%@,%i",[MapUtils padInt:x padTo:4],[MapUtils padInt:y padTo:4],value];
        [arr addObject:tileInfo];
    }}
    

    
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    RMMapboxSource *tileSource = [[RMMapboxSource alloc] initWithMapID:@"mapbox.light"];
    
    
    self.map = [[RMMapView alloc] initWithFrame:self.view.bounds
                                  andTilesource:tileSource];
    
    
    // set zoom
    self.map.zoom = 6;
    self.map.maxZoom = 6;
    self.map.minZoom = 2;
    self.map.autoresizingMask =  UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight ;
    // set coordinates
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(33.5,32.0);
    
    // center the map to the coordinates
    self.map.centerCoordinate = center;

    [_viewMapHolder insertSubview:self.map atIndex:0];
    

    self.map.tileCache.backgroundCacheDelegate = self;
    self.map.delegate=self;
    
    for (RMDatabaseCache * cash in self.map.tileCache.tileCaches){
        [cash setCapacity:10000];
        [cash setMinimalPurge:10];
        
    }
    if (! [[NSUserDefaults standardUserDefaults]boolForKey:@"offlineIsReady"]) {

        

        int minDownloadZoom = 0;
        int maxDownloadZoom = 6;
        
        CLLocationCoordinate2D southWest = CLLocationCoordinate2DMake(-85,-180);
        CLLocationCoordinate2D northEast = CLLocationCoordinate2DMake(85,180);
        
        self.count = 0.0;
        self.noTilesToDownload = [self.map.tileCache tileCountForSouthWest:southWest northEast:northEast minZoom:minDownloadZoom maxZoom:maxDownloadZoom];
        _progressBar.type               =  YLProgressBarTypeRounded ;
        _progressBar.indicatorTextDisplayMode     =  YLProgressBarIndicatorTextDisplayModeProgress;

        _progressBar.progressTintColor  = [UIColor blueColor];
        _progressBar.stripesOrientation = YLProgressBarStripesOrientationVertical;
        _progressBar.stripesDirection   = YLProgressBarStripesDirectionLeft;
        _progressBar.progressStretch          = YES;
        _progressBar.trackTintColor = [UIColor whiteColor];
        
//        NSLog (@"%lu",(unsigned long)[self.map.tileCache tileCountForSouthWest:southWest northEast:northEast minZoom:minDownloadZoom maxZoom:maxDownloadZoom]);
        [self.map.tileCache beginBackgroundCacheForTileSource:self.map.tileSource southWest:southWest northEast:northEast minZoom:minDownloadZoom maxZoom:maxDownloadZoom];
    } else {
        _viewDownload.hidden = true;
    }
    
    //altitude init
    _selectedAltitudeLayer = 5;
    
    _pickerAltitude.delegate = self;
    _pickerAltitude.dataSource = self;
    [_pickerAltitude selectRow:_selectedAltitudeLayer inComponent:0 animated:NO];

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - tile cache
-(void)tileCache:(RMTileCache *)tileCache didBackgroundCacheTile:(RMTile)tile withIndex:(NSUInteger)tileIndex ofTotalTileCount:(NSUInteger)totalTileCount {
    self.count ++;
    self.progressBar.progress = self.count / self.noTilesToDownload;
   // NSLog (@"Cached-%i",self.count);
}

-(void) tileCache:(RMTileCache *)tileCache didReceiveError:(NSError *)error whenCachingTile:(RMTile)tile    {
    NSLog (@"Error");
}
-(void)tileCacheDidFinishBackgroundCache:(RMTileCache *)tileCache {
    [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"offlineIsReady"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    _viewDownload.hidden = true;
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Map downnload for offline use completed." message:@"" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];

    [alert show];
    
}


#pragma mark - mapbox delegate
-(void) mapViewRegionDidChange:(RMMapView *)mapView {

    
}
- (RMMapLayer *)mapView:(RMMapView *)mapView layerForAnnotation:(RMAnnotation *)annotation
{


    if (annotation.isUserLocationAnnotation)
        return nil;
    int  zoomLevelForAnnotation;
    switch ((int)mapView.zoom) {
        case 6:
            zoomLevelForAnnotation = 11;
            break;
        case 5:
            zoomLevelForAnnotation =11;
            break;
        case 4:
            zoomLevelForAnnotation =10;
            break;
        case 3:
            zoomLevelForAnnotation =10;
            break;
        case 2:
            zoomLevelForAnnotation =9;
            break;
        case 1:
        case 0:
            zoomLevelForAnnotation =7;
            break;
        default:
            break;
    }

    int zoomFactor = pow(2.0, zoomLevelForAnnotation);
    RMCircle *circle = [[RMCircle alloc] initWithView:mapView radiusInMeters:40075.016686*1000/zoomFactor/2];

    UIColor * colorLevel1 = kColorLight;
    UIColor * colorLevel2 = kColorLightModerate;
    UIColor * colorLevel3 = kColorModerate;
    UIColor * colorLevel4 = kColorSevere;
    UIColor * colorLevel5 = kColorExtream;
    
    NSNumber * turbulenceSavirity = annotation.userInfo;
    UIColor * annotationColor;
    switch ([turbulenceSavirity intValue]) {
        case 1:
            annotationColor =colorLevel1;
            break;
        case 2:
            annotationColor =colorLevel2;
            break;
        case 3:
            annotationColor =colorLevel3;
            break;
        case 4:
            annotationColor =colorLevel4;
            break;
        case 5:
            annotationColor =colorLevel5;
            break;
        default:
            break;
    } 
    circle.fillColor = annotationColor;
    circle.lineWidthInPixels = 0.0;
    
    return circle;
}


- (void)singleTapOnMap:(RMMapView *)map at:(CGPoint)point
{
    NSLog(@"You tapped at %f, %f",
          [map pixelToCoordinate:point].latitude,
          [map pixelToCoordinate:point].longitude);

}
-(void) beforeMapZoom:(RMMapView *)map byUser:(BOOL)wasUserAction {
    [map removeAllAnnotations    ];
}
- (void)beforeMapMove:(RMMapView *)map byUser:(BOOL)wasUserAction {


//    [map removeAllAnnotations    ];

}

- (void)afterMapZoom:(RMMapView *)map byUser:(BOOL)wasUserAction{

    [self addAnnotationsWithMap:map];

}
- (void)afterMapMove:(RMMapView *)map byUser:(BOOL)wasUserAction{
    
//    [self addAnnotationsWithMap:map];
    
}



#pragma mark - logic functions
-(void) addAnnotationsWithMap:(RMMapView *)map {
    // add test tiles
    
    NSString *  zoomLevelForAnnotation;
    int zoomFactor;
    switch ((int)map.zoom) {
        case 6:
            zoomLevelForAnnotation =@"11";
            zoomFactor = pow(2,11);
            break;
        case 5:
            zoomLevelForAnnotation =@"11";
            zoomFactor = pow(2,10);
            break;
        case 4:
            zoomLevelForAnnotation =@"10";
            zoomFactor = pow(2,10);
            break;
        case 3:
            zoomLevelForAnnotation =@"10";
            zoomFactor = pow(2,9);
            break;
        case 2:
            zoomLevelForAnnotation =@"09";
            zoomFactor = pow(2,9);
            break;
        case 1:
        case 0:
            zoomLevelForAnnotation =@"07";
            zoomFactor = pow(2,8);
            break;
        default:
            break;
    }
    NSMutableArray * arr = [NSMutableArray new];
    for (NSString * tileData in self.tileData[self.selectedAltitudeLayer]) {
        NSArray *items = [tileData componentsSeparatedByString:@","];
        NSString * strX = items[0];
        NSString * strY = items[1];
        NSString * strValue = items[2];
        int x = strX.intValue;
        int y = strY.intValue;
        int value = strValue.intValue;
        
        
        
        NSString * tileAddress = [NSString stringWithFormat:@"%@%@%@",[MapUtils padInt:x padTo:4],[MapUtils padInt:y padTo:4],@"11"];
        CLLocationCoordinate2D centerTileCoordinate = [MapUtils getCenterCoordinatesForTilePathForZoom:tileAddress];
        NSString * tileAddressNew = [MapUtils transformWorldCoordinateToTilePathForZoom:(int)zoomLevelForAnnotation.integerValue fromLon:centerTileCoordinate.longitude fromLat:centerTileCoordinate.latitude];
        centerTileCoordinate = [MapUtils getCenterCoordinatesForTilePathForZoom:tileAddressNew];
        
        
        RMAnnotation *annotation = [[RMAnnotation alloc] initWithMapView:self.map
                                                              coordinate:centerTileCoordinate
                                                                andTitle:@"Coverage Area"];
        
        
        annotation.userInfo = [NSNumber numberWithInt:value];
        [arr addObject:annotation];
        
        
    }
    [self.map addAnnotations:arr];
}

#pragma mark - UIpicker
// The number of columns of data
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

// The number of rows of data
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return 16  ;
}


// Catpure the picker view selection
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    _selectedAltitudeLayer = (int)row;
    [self.map removeAllAnnotations];
    [self addAnnotationsWithMap:self.map];
}
- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view{
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, pickerView.frame.size.width, 20)];
    label.backgroundColor = [UIColor grayColor];
    label.textColor = [UIColor whiteColor];
    label.textAlignment= NSTextAlignmentCenter;
    label.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20];
    label.text = [NSString stringWithFormat:@" %ld K", (kAltitude_Min+row * kAltitude_Step)];
    return label;
}



#pragma mark - Popovers
- (IBAction)btnBrightness_Clicked:(UIBarButtonItem *)sender {
    if (_brightnessController == nil) {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        _brightnessController  = [sb instantiateViewControllerWithIdentifier:@"Brightness"];
    }
    _brightnessPopover = [[UIPopoverController alloc] initWithContentViewController:_brightnessController];
    _brightnessPopover.popoverContentSize =  CGSizeMake(300.0, 80.0);
    _brightnessPopover.backgroundColor = _navBar.backgroundColor;
    _brightnessController.view.backgroundColor = _navBar.barTintColor;
    if (self.presentedViewController) {
        [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    }
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        
    [_brightnessPopover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    }];

}


- (IBAction)btnAbout_Clicked:(id)sender {
    if (_aboutViewController == nil) {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        _aboutViewController  = [sb instantiateViewControllerWithIdentifier:@"About"];
    }
    _aboutPopover = [[UIPopoverController alloc] initWithContentViewController:_aboutViewController];
    _aboutPopover.popoverContentSize =  CGSizeMake(400.0, 400.0);
    _aboutPopover.backgroundColor = _navBar.backgroundColor;
    _aboutViewController.view.backgroundColor = _navBar.barTintColor;
    if (self.presentedViewController) {
        [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    }
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        
            [_aboutPopover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    }];

}
- (IBAction)btnPilotReport_Clicked:(UIButton *)sender {
    if (_pilotReportController == nil) {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        _pilotReportController  = [sb instantiateViewControllerWithIdentifier:@"PilotReport"];
    }
    _pilotReportPopover = [[UIPopoverController alloc] initWithContentViewController:_pilotReportController];
    _pilotReportPopover.popoverContentSize =  CGSizeMake(100.0, 100.0);
    _pilotReportPopover.backgroundColor = _navBar.backgroundColor;
    _pilotReportController.view.backgroundColor = _navBar.backgroundColor;
    _pilotReportController.turbulenceLevel = sender.tag;
    if (self.presentedViewController) {
        [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    }
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        
    [_pilotReportPopover presentPopoverFromRect:sender.frame inView:self.viewLeftMenu permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
    }];

}

#pragma mark - timers

- (void) checkGoodLocation:(NSTimer *)incomingTimer
{
    if ([LocationManager sharedManager].isLocationGood) {
        _lblGpsSignal.backgroundColor = [Helpers r:102 g:205 b:0 alpha:1.0];
        ZLTile tile = [[LocationManager sharedManager] getCurrentTile];
        NSLog(@"%i/%i",tile.x, tile.y);
    } else {
        _lblGpsSignal.backgroundColor = [UIColor redColor];
    }
}
#pragma mark - mixc
- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end
