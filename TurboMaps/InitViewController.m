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
#import "AirportSearchViewController.h"
#import "Turbulence.h"
//managers
#import "LocationManager.h"
#import "RecorderManager.h"
#import "RouteManager.h"
#import "TurbulenceManager.h"



@interface InitViewController ()<AboutViewDelegate,RMTileCacheBackgroundDelegate,RMMapViewDelegate,UIPickerViewDataSource,UIPickerViewDelegate,AirportSearchDelegate>
@property (nonatomic,strong) RMMapView * map;




//right menu bar
@property (weak, nonatomic) IBOutlet UIView *viewRightMenu;
@property (weak, nonatomic) IBOutlet UIButton *btnTakoff;
@property (weak, nonatomic) IBOutlet UIButton *btnLand;
@property (weak, nonatomic) IBOutlet UILabel *lblTakoff;
@property (weak, nonatomic) IBOutlet UILabel *lblLand;

@property (weak, nonatomic) IBOutlet UIPickerView *pickerAltitude;

//top bar
@property (weak, nonatomic) IBOutlet UIToolbar *navBar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *barItemGPS;

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





//legend
@property (weak, nonatomic) IBOutlet UILabel *lblLegendLight;
@property (weak, nonatomic) IBOutlet UILabel *lblLegentLightModerate;
@property (weak, nonatomic) IBOutlet UILabel *lblLegentModerate;
@property (weak, nonatomic) IBOutlet UILabel *lblLegentSevere;
@property (weak, nonatomic) IBOutlet UILabel *lblLegentExtream;

@property (weak, nonatomic) IBOutlet UILabel *lblLastUpdate;



//Popovers
@property (nonatomic, strong) BrightnessViewController *brightnessController;
@property (nonatomic, strong) UIPopoverController *brightnessPopover;

@property (nonatomic,strong) PilotReportViewController * pilotReportController;
@property (nonatomic,strong) UIPopoverController * pilotReportPopover;

@property (nonatomic,strong) AboutViewController * aboutViewController;
@property (nonatomic,strong) UIPopoverController * aboutPopover;

@property (nonatomic,strong) AirportSearchViewController * airportSearchViewController;
@property (nonatomic,strong) UIPopoverController * airportSearchPopover;

//timers
@property (nonatomic,strong) NSTimer * timerGpsSignal;
@end

@implementation InitViewController


-(void)dealloc{
    NSLog(@"Dealloc initViewController");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // init location manager
    [LocationManager sharedManager];
    
    //init recorder manager
    [RecorderManager sharedManager];
    
    //init route manager
    [RouteManager sharedManager];
    
    //init turbulence manager manager
    [TurbulenceManager sharedManager];

    //notifications observers
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(turbuleceUpdatedFromServer:) name:kNotification_turbulenceServerNewFile object:nil];
    
    [[RMConfiguration sharedInstance] setAccessToken:@"pk.eyJ1Ijoieml2bGV2eSIsImEiOiJwaEpQeUNRIn0.OZupy_Vjyl5eRCRlgV6otg"];
    

    //Download progress bar init
    [Helpers roundCornersOnView:_viewDownload onTopLeft:YES topRight:YES bottomLeft:YES bottomRight:YES radius:8.0];
    _progressBar.progress =0.0;
    
    
    // topbar init
    _navBar.clipsToBounds=YES;
    _navBar.backgroundColor=kColorToolbarBackground;
    _navBar.tintColor = [UIColor clearColor];
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
    
    //airports init
    _lblTakoff.text = [RouteManager sharedManager].currentFlight.originAirport.ICAO;
    _lblLand.text = [RouteManager sharedManager].currentFlight.destinationAirport.ICAO;
    



    
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];

    //set timer to watch for good location
    _timerGpsSignal = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self
                                                     selector:@selector(checkGoodLocation:) userInfo:nil repeats:YES];
    
    // configure map tile source based on previous metadata if available
    RMMapboxSource * tileSource;
    NSString * tileJSON = [[NSUserDefaults standardUserDefaults]objectForKey:@"tileJSON"];
    if (tileJSON) {
        tileSource = [[RMMapboxSource alloc]initWithTileJSON:tileJSON];
    } else {
        tileSource = [[RMMapboxSource alloc] initWithMapID:@"mapbox.light"];
    }

    
    self.map = [[RMMapView alloc] initWithFrame:self.view.bounds
                                  andTilesource:tileSource];
    
    
    // set zoom
    self.map.zoom = 6;
    self.map.maxZoom = 6;
    self.map.minZoom = 3;
//    self.map.autoresizingMask =  UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight ;
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
    if (![[NSUserDefaults standardUserDefaults]boolForKey:@"offlineIsReady"]) {

        

        int minDownloadZoom = 3;
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

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [_timerGpsSignal invalidate];
    _timerGpsSignal = nil;
    _map=nil;
}

-(void) viewDidAppear:(BOOL)animated    {
    [super viewDidAppear:animated];
     [self addAnnotationsWithMap:_map];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - tile cache
-(void)tileCache:(RMTileCache *)tileCache didBackgroundCacheTile:(RMTile)tile withIndex:(NSUInteger)tileIndex ofTotalTileCount:(NSUInteger)totalTileCount {
    self.count ++;
    self.progressBar.progress = self.count / self.noTilesToDownload;
}

-(void) tileCache:(RMTileCache *)tileCache didReceiveError:(NSError *)error whenCachingTile:(RMTile)tile    {
    NSLog (@"Error");
}
-(void)tileCacheDidFinishBackgroundCache:(RMTileCache *)tileCache {
    [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"offlineIsReady"];
    
    NSString * tileJSON =  ((RMMapboxSource *)_map.tileSource).tileJSON;
    [[NSUserDefaults standardUserDefaults] setObject:tileJSON forKey:@"tileJSON"];

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

    zoomLevelForAnnotation = 11;

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
            annotationColor =colorLevel5;
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
    [map removeAllAnnotations];
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
    NSDictionary * dict = [[TurbulenceManager sharedManager]getTurbulanceDictionaryArLevel:self.selectedAltitudeLayer];
    
    for ( Turbulence * turbulence in [dict allValues]) {
        int x = turbulence.tileX;
        int y = turbulence.tileY;
        int value = turbulence.severity;
        
        
        
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

    Airport * origin = [RouteManager sharedManager].currentFlight.originAirport;
    Airport * dest = [RouteManager sharedManager].currentFlight.destinationAirport;
    if (![origin.ICAO isEqualToString:dest.ICAO] && dest && origin) {
        CLLocationCoordinate2D start = CLLocationCoordinate2DMake(origin.latitude, origin.longitude);
        CLLocationCoordinate2D end = CLLocationCoordinate2DMake(dest.latitude, dest.longitude);
        RMAnnotation *annotation = [[RMAnnotation alloc] initWithMapView:self.map
                                                              coordinate:start
                                                                andTitle:@"Coverage Area"];
        [arr addObject:annotation];
        annotation = [[RMAnnotation alloc] initWithMapView:self.map
                                                coordinate:end
                                                  andTitle:@"Coverage Area"];
        [arr addObject:annotation];
        RMAnnotation * GC = [[RMGreatCircleAnnotation alloc] initWithMapView:_map coordinate1:start coordinate2:end];
        [arr addObject:GC];
        GC = [[RMGreatCircleAnnotation alloc] initWithMapView:_map coordinate1:end coordinate2:start];
        
        [self.map addAnnotations:arr];

        
    }
    
    //update last server update
    long lastTurbulenceUpdateDate = [[TurbulenceManager sharedManager]getSavedServerUpdateSince1970];
    if (lastTurbulenceUpdateDate == 0) {
        _lblLastUpdate.text =@"No data is available";
    } else {
        _lblLastUpdate.text =[NSString stringWithFormat:@"Updated @ %@",[Helpers getGMTTimeString:[NSDate dateWithTimeIntervalSince1970:lastTurbulenceUpdateDate] withFormat:@"dd/MM HH:mm"]];
    }
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
    _brightnessPopover.popoverContentSize =  CGSizeMake(300.0, 150.0);
    _brightnessPopover.backgroundColor = kColorToolbarBackground;
    _brightnessController.view.backgroundColor = kColorToolbarBackground;
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
        _aboutViewController.delegate=self;
    }
    _aboutPopover = [[UIPopoverController alloc] initWithContentViewController:_aboutViewController];
    _aboutPopover.popoverContentSize =  CGSizeMake(400.0, 400.0);
    _aboutPopover.backgroundColor = kColorToolbarBackground;
    _aboutViewController.view.backgroundColor = kColorToolbarBackground;
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
    _pilotReportPopover.backgroundColor = kColorToolbarBackground;
    _pilotReportController.view.backgroundColor = kColorToolbarBackground;
    _pilotReportController.turbulenceLevel = sender.tag;
    if (self.presentedViewController) {
        [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    }
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        
    [_pilotReportPopover presentPopoverFromRect:sender.frame inView:self.viewLeftMenu permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
    }];

}


- (IBAction)btnTakeoffLanding_clocked:(UIButton *)sender {
    
    if (_airportSearchViewController == nil) {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        _airportSearchViewController  = [sb instantiateViewControllerWithIdentifier:@"AirportSearch"];
    }
    _airportSearchPopover = [[UIPopoverController alloc] initWithContentViewController:_airportSearchViewController];
    _airportSearchPopover.popoverContentSize =  CGSizeMake(250.0, 300.0);
    _airportSearchPopover.backgroundColor = kColorToolbarBackground;
    _airportSearchViewController.view.backgroundColor = kColorToolbarBackground;
    _airportSearchViewController.delegate=self;
    if (sender.tag ==1) { //takeoff
        _airportSearchViewController.taragetControl = @"takeoff";
        _airportSearchViewController.inputAirportICAO = _lblTakoff.text;
    } else { //landing
        _airportSearchViewController.taragetControl = @"landing";
        _airportSearchViewController.inputAirportICAO = _lblLand.text;
    }

    
    if (self.presentedViewController) {
        [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    }
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        
        [_airportSearchPopover presentPopoverFromRect:sender.frame inView:self.viewRightMenu permittedArrowDirections:UIPopoverArrowDirectionRight animated:YES];
    }];
    
}

#pragma mark - timers

- (void) checkGoodLocation:(NSTimer *)incomingTimer
{
    if ([LocationManager sharedManager].isLocationGood) {
        _barItemGPS.tintColor = [Helpers r:102 g:205 b:0 alpha:1.0];

    } else {
        _barItemGPS.tintColor = [UIColor redColor];
    }
}

#pragma mark - notification handling
-(void)turbuleceUpdatedFromServer:(NSNotification*)notification
{
    NSLog(@"Server Updated");
     [_map removeAllAnnotations];
    [self addAnnotationsWithMap:_map];
}
#pragma mark - misc
- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark - about view delegate
-(void) logout {
    NSLog (@"About logout");
    [_aboutPopover dismissPopoverAnimated:NO];
    _aboutPopover = nil;
    [self performSegueWithIdentifier:@"segueUnwind" sender:self];
}


#pragma mark - airport search delegate
-(void)airportSelected:(Airport *)airport toTargetControl:(NSString *)targetControl
{
    [self.airportSearchPopover dismissPopoverAnimated:YES];

    if ([targetControl isEqualToString:@"takeoff"]) {
        self.lblTakoff.text = airport.ICAO;
        [RouteManager sharedManager].currentFlight.originAirport = airport;
        
        
    } else {
        self.lblLand.text = airport.ICAO;
        [RouteManager sharedManager].currentFlight.destinationAirport = airport;
    }
    [_map removeAllAnnotations];
    [self addAnnotationsWithMap:_map];
}

-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    
    
    self.map.autoresizingMask =  UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight ;
    [_map removeAllAnnotations];
    [self addAnnotationsWithMap:_map];
}

@end
