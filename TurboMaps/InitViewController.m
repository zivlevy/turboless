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
#import "FlightNumberViewController.h"
#import "Turbulence.h"
//managers
#import "LocationManager.h"
#import "RecorderManager.h"
#import "RouteManager.h"
#import "TurbulenceManager.h"
#import "AccelerometerManager.h"
#import "DebugManager.h"
#import "AlertsManager.h"

#import "AKPickerView.h"
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSInteger, ZLAltitudeModeState) {
    ZLAltitudeModeManual          = 0,
    ZLAltitudeModeAuto     = 1,
    ZLAltitudeModeAutoSuspended = 2,
    ZLAltitudeModeAutoUserSuspended = 3,
    ZLAltitudeModeAutoUserSuspendedBadGps = 4,
};


@interface InitViewController ()<AboutViewDelegate,RMTileCacheBackgroundDelegate,RMMapViewDelegate,UIPickerViewDataSource,UIPickerViewDelegate,AirportSearchDelegate,AKPickerViewDataSource,AKPickerViewDelegate,AlertsManagerDelegate>
@property (nonatomic,strong) RMMapView * map;


@property (nonatomic,strong)NSMutableDictionary * currentTileAnotations;

//right menu bar
@property (weak, nonatomic) IBOutlet UIView *viewRightMenu;
@property (weak, nonatomic) IBOutlet UIButton *btnTakoff;
@property (weak, nonatomic) IBOutlet UIButton *btnLand;
@property (weak, nonatomic) IBOutlet UILabel *lblTakoff;
@property (weak, nonatomic) IBOutlet UILabel *lblLand;
@property (weak, nonatomic) IBOutlet UIButton *btnFlightNumber;

@property (nonatomic,strong) AKPickerView * pickerHistory;
@property (weak, nonatomic) IBOutlet UIPickerView *pickerAltitude;

//top bar
@property (weak, nonatomic) IBOutlet UIToolbar *navBar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *barItemGPS;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *BarItemTitle;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *barItemUserLocation;


//left menu bar
@property (weak, nonatomic) IBOutlet UIView *viewLeftMenu;
@property (weak, nonatomic) IBOutlet UIView *viewTurbulence;
@property (weak, nonatomic) IBOutlet UIImageView *imageShake;
@property (weak, nonatomic) IBOutlet UIButton *btnDebug;

// ** btn report
@property (weak, nonatomic) IBOutlet UIButton *btnReport_light;
@property (weak, nonatomic) IBOutlet UIButton *btnReport_lightModerate;
@property (weak, nonatomic) IBOutlet UIButton *btnReport_moderate;
@property (weak, nonatomic) IBOutlet UIButton *btnReport_severe;
@property (weak, nonatomic) IBOutlet UIButton *btnReport_Extreme;

//bottom bar
@property (weak, nonatomic) IBOutlet UIView *viewBottomBar;

//mapHolder view
@property (weak, nonatomic) IBOutlet UIView *viewMapHolder;

//download view
@property (weak, nonatomic) IBOutlet UIView *viewDownload;
@property (weak, nonatomic) IBOutlet YLProgressBar *progressBar;
@property float count; //how many tiles were downloaded
@property float noTilesToDownload;

//holds the current altitude layer to be displayed
@property int selectedAltitudeLayer;
//holds the differance the user scrolled to 0=Auto 2,4,6... -2,-4,-6...
@property int selectedALtitudeDelta;





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

@property (nonatomic,strong) FlightNumberViewController * flightNumberViewController;
@property (nonatomic,strong) UIPopoverController * flightNumberPopover;

@property (nonatomic,strong) AirportSearchViewController * airportSearchViewController;
@property (nonatomic,strong) UIPopoverController * airportSearchPopover;

//timers
@property (nonatomic,strong) NSTimer * timerGpsSignal; //check gps signal and location
@property (nonatomic,strong) NSTimer * timerHideTurbulenceMarker; //hide marker after showing new turbulence event

//auto altitude
@property ZLAltitudeModeState altitudeModeState;
@property bool isShouldShowAutoScroll;
@property int currentAltitudeLevel;
@property (nonatomic,strong) NSTimer * timerAltitudeReturnToAuto; //after user change altitude in auto mode, return to auto
@property (weak, nonatomic) IBOutlet UISwitch *switchAltitudeAuto;
@property (weak, nonatomic) IBOutlet UIView *viewAutoAltutude;

//Alert View
@property (weak, nonatomic) IBOutlet UIView *viewAlertView;
@property (weak, nonatomic) IBOutlet UIButton *btnAlertSilence;
@property (weak, nonatomic) IBOutlet UIView *viewAlertAbove;
@property (weak, nonatomic) IBOutlet UIView *viewAlertBelow;
@property (weak, nonatomic) IBOutlet UIView *viewAlertCurrentAlt;
@property (weak, nonatomic) IBOutlet UILabel *lblAlertViewHeader;

//Alert sound
@property (nonatomic,strong) AVAudioPlayer *avSound;
@property (nonatomic,strong) NSTimer * timerAlertSound;
@end

@implementation InitViewController


-(void)dealloc{
    NSLog(@"Dealloc initViewController");
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_map removeObserver:self forKeyPath:@"userTrackingMode"];
    [_timerAltitudeReturnToAuto invalidate];
    [_timerGpsSignal invalidate];
    [_timerAlertSound invalidate];
    [_timerHideTurbulenceMarker  invalidate];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // init location manager
    [LocationManager sharedManager];
    
    //init recorder manager
    [RecorderManager sharedManager];
    
    //init route manager
    [RouteManager sharedManager];
    
    //init turbulence manager
    [TurbulenceManager sharedManager];
    
    //init accelerometer  manager
    [AccelerometerManager sharedManager];
    
    //init debug manager
    [DebugManager sharedManager];
    
    //init alert manager
    [AlertsManager sharedManager].delegate = self;
    
    //notifications observers
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(turbuleceUpdatedFromServer:) name:kNotification_turbulenceServerNewFile object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newTurbulenceEvent:) name:kNotification_TurbulenceEvent object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceInMotion:) name:kNotification_DeviceInMotion object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceStatic:) name:kNotification_DeviceInStatic object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(flightNumberChanged:) name:kNotification_FlightNumberChanged object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationStatusChanged:) name:kNotification_LocationStatusChanged object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(headingStatusChanged:) name:kNotification_HeadingStatusChanged object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(invalidToken:) name:kNotification_InvalidToken object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationChanged:) name:kNotification_NewGPSLocation object:nil];
    
    
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
    _btnReport_severe.backgroundColor = kColorModerateSevere;
    _btnReport_Extreme.backgroundColor = kColorSevere;
    
    [Helpers makeRound:_btnReport_light borderWidth:1 borderColor:[UIColor whiteColor]];
    [Helpers makeRound:_btnReport_lightModerate borderWidth:1 borderColor:[UIColor whiteColor]];
    [Helpers makeRound:_btnReport_moderate borderWidth:1 borderColor:[UIColor whiteColor]];
    [Helpers makeRound:_btnReport_severe borderWidth:1 borderColor:[UIColor whiteColor]];
    [Helpers makeRound:_btnReport_Extreme borderWidth:1 borderColor:[UIColor whiteColor]];
    
    [Helpers makeRound:_btnDebug borderWidth:1 borderColor:[UIColor whiteColor]];
    NSString * isDebug = [[NSUserDefaults standardUserDefaults] objectForKey:@"isDebug"];
    if (isDebug) {
        _btnDebug.hidden = false;
    } else {
        _btnDebug.hidden = true;
    }
    //legend init
    _lblLegendLight.backgroundColor = kColorLight;
    _lblLegentLightModerate.backgroundColor = kColorLightModerate;
    _lblLegentModerate.backgroundColor = kColorModerate;
    _lblLegentSevere.backgroundColor = kColorModerateSevere;
    _lblLegentExtream.backgroundColor = kColorSevere;
    
    //airports init
    _lblTakoff.text = [RouteManager sharedManager].currentFlight.originAirport.ICAO;
    _lblLand.text = [RouteManager sharedManager].currentFlight.destinationAirport.ICAO;
    
    //flight number init
    [_btnFlightNumber setTitle:[[NSUserDefaults standardUserDefaults]objectForKey:@"flightNumber"]  forState:UIControlStateNormal]  ;
    [Helpers makeRound:_btnFlightNumber borderWidth:1 borderColor:[UIColor whiteColor]];
    //turbulence view init
    [Helpers makeRound:_viewTurbulence borderWidth:1 borderColor:[UIColor whiteColor]];
    _viewTurbulence.hidden = true;
    
    //keep display on init
    if ([[NSUserDefaults standardUserDefaults] boolForKey :@"keepDisplayOn"]) {
        [UIApplication sharedApplication].idleTimerDisabled = YES;
    } else {
        [UIApplication sharedApplication].idleTimerDisabled = NO;
    }
    
    // altitude mode
    _viewAutoAltutude.hidden=true; //start hidden
    _isShouldShowAutoScroll = false;
    
    
    _currentAltitudeLevel = 1;
    [self setManualMode];
    
    
    
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    //set timer to watch for good location
    _timerGpsSignal = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self
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
    
    //User location
    
    _map.showsUserLocation   = YES;
    _map.userTrackingMode = RMUserTrackingModeFollow;
    _map.userTrackingMode = RMUserTrackingModeNone;
    _map.tintColor = [UIColor colorWithRed:0.5 green:0.6 blue:1.0 alpha:1];
    //kvo observer
    [_map addObserver:self forKeyPath:@"userTrackingMode"      options:NSKeyValueObservingOptionNew context:nil];
    
    // set zoom
    self.map.zoom = 6;
    self.map.maxZoom = 6;
    self.map.minZoom = 1;
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
        
        
        
        int minDownloadZoom = 1;
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
    
    _selectedAltitudeLayer = (kAltitude_InitialAltitudeForPicker - kAltitude_Min)  / kAltitude_Step +1;
    
    
    
    _pickerAltitude.delegate = self;
    _pickerAltitude.dataSource = self;
    [_pickerAltitude selectRow:_selectedAltitudeLayer-1 inComponent:0 animated:NO];
    
    //history init
    
    _pickerHistory = [[AKPickerView alloc] initWithFrame:CGRectMake(280 ,10,75,30)];
    [Helpers makeRound:_pickerHistory borderWidth:1 borderColor:[UIColor whiteColor]];
    _pickerHistory.delegate = self;
    _pickerHistory.dataSource = self;
    //    _pickerHistory.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.viewBottomBar addSubview:_pickerHistory];
    _pickerHistory.backgroundColor = [Helpers r:59 g:59 b:59 alpha:1.0];
    _pickerHistory.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
    _pickerHistory.highlightedFont = [UIFont fontWithName:@"HelveticaNeue" size:14];
    _pickerHistory.textColor = [UIColor whiteColor];
    _pickerHistory.highlightedTextColor = [UIColor whiteColor];
    _pickerHistory.interitemSpacing = 15.0;
    _pickerHistory.fisheyeFactor = 0.005;
    _pickerHistory.pickerViewStyle = AKPickerViewStyle3D;
    _pickerHistory.maskDisabled = true;
    
    [_pickerHistory reloadData];
    
    //Alert init
    [[AlertsManager sharedManager] setCutOffTime:6 * 3600];
    [self alertStateChanged:ZLAlert_NoAlerts];
    [Helpers makeRoundCorners:_viewAlertView radius:10 borderWidth:1 borderColor:[UIColor whiteColor]];
    [Helpers makeRoundCorners:_viewAlertAbove radius:5 borderWidth:1 borderColor:[UIColor whiteColor]];
    [Helpers makeRoundCorners:_viewAlertCurrentAlt radius:5 borderWidth:1 borderColor:[UIColor whiteColor]];
    [Helpers makeRoundCorners:_viewAlertBelow radius:5 borderWidth:1 borderColor:[UIColor whiteColor]];
    [Helpers makeRound:_btnAlertSilence borderWidth:1 borderColor:[UIColor whiteColor]];
    
    //Alert Sound init
    NSURL *soundURL = [[NSBundle mainBundle] URLForResource:@"sound"
                                              withExtension:@"wav"];
    
    
    _avSound = [[AVAudioPlayer alloc] initWithContentsOfURL:soundURL error:nil];
    
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
-(void)mapView:(RMMapView *)mapView didSelectAnnotation:(RMAnnotation *)annotation{
    NSLog(@"%@",annotation.title);
}
- (RMMapLayer *)mapView:(RMMapView *)mapView layerForAnnotation:(RMAnnotation *)annotation
{
    
    
    if (annotation.isUserLocationAnnotation){
        return nil;
    }
    
    // Alert Zone Border
    if (([annotation.title isEqualToString:@"AlertZoneBorder"])) {
        RMShape *shape = [[RMShape alloc] initWithView:mapView];
        
        // set line color and width
        shape.lineColor = [UIColor colorWithRed:0.224 green:0.671 blue:0.780 alpha:1.000];
        shape.lineWidth = 1.0;
        
        for (CLLocation *location in (NSArray *)annotation.userInfo)
            [shape addLineToCoordinate:location.coordinate];
        
        return shape;
    }
    
    ///////////// rest of annotations
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
            zoomLevelForAnnotation =9;
            break;
        case 2:
            zoomLevelForAnnotation =8;
            break;
        case 1:
        case 0:
            zoomLevelForAnnotation =8;
            break;
        default:
            break;
    }
    
    //zoomLevelForAnnotation = 11;
    
    int zoomFactor = pow(2.0, zoomLevelForAnnotation);
    RMCircle *circle = [[RMCircle alloc] initWithView:mapView radiusInMeters:40075.016686*1000/zoomFactor/2];
    UIColor * colorLevel0 = kColorNone;
    UIColor * colorLevel1 = kColorLight;
    UIColor * colorLevel2 = kColorLightModerate;
    UIColor * colorLevel3 = kColorModerate;
    UIColor * colorLevel4 = kColorModerateSevere;
    UIColor * colorLevel5 = kColorSevere;
    
    NSNumber * turbulenceSavirity = annotation.userInfo;
    UIColor * annotationColor;
    switch ([turbulenceSavirity intValue]) {
        case 0:
            annotationColor =colorLevel0;
            break;
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
    long start = [[NSDate date] timeIntervalSince1970];
    NSLog(@"Start - %ld",start);
    NSString *  zoomLevelForAnnotation;
    int zoomFactor;
    switch ((int)map.zoom) {
        case 6:
            zoomLevelForAnnotation =@"11";
            zoomFactor = pow(2,11);
            break;
        case 5:
            zoomLevelForAnnotation =@"11";
            zoomFactor = pow(2,11);
            break;
        case 4:
            zoomLevelForAnnotation =@"10";
            zoomFactor = pow(2,10);
            break;
        case 3:
            zoomLevelForAnnotation =@"09";
            zoomFactor = pow(2,9);
            break;
        case 2:
            zoomLevelForAnnotation =@"08";
            zoomFactor = pow(2,8);
            break;
        case 1:
        case 0:
            zoomLevelForAnnotation =@"08";
            zoomFactor = pow(2,8);
            break;
        default:
            break;
    }
    
    
    NSMutableArray * arr = [NSMutableArray new];
    NSDictionary * dict = [[TurbulenceManager sharedManager]getTurbulanceDictionaryArLevel:self.selectedAltitudeLayer-1];
    
    //holds annotations for tileXY for aggregation by zoom
    _currentTileAnotations = [NSMutableDictionary new];
    
    for ( Turbulence * turbulence in [dict allValues]) {
        int x = turbulence.tileX;
        int y = turbulence.tileY;
        
        
        
        
        NSString * tileAddress = [NSString stringWithFormat:@"%@%@%@",[MapUtils padInt:x padTo:4],[MapUtils padInt:y padTo:4],@"11"];
        CLLocationCoordinate2D centerTileCoordinate = [MapUtils getCenterCoordinatesForTilePathForZoom:tileAddress];
        NSString * tileAddressNew = [MapUtils transformWorldCoordinateToTilePathForZoom:(int)zoomLevelForAnnotation.integerValue fromLon:centerTileCoordinate.longitude fromLat:centerTileCoordinate.latitude];
        centerTileCoordinate = [MapUtils getCenterCoordinatesForTilePathForZoom:tileAddressNew];
        
        //do aggergation of turbulence data
        
        Turbulence * turbulenceDataInLocation = [_currentTileAnotations objectForKey:tileAddressNew];
        if (!turbulenceDataInLocation) {
            [_currentTileAnotations setObject:turbulence forKey:tileAddressNew];
            
        }
        else if (turbulenceDataInLocation.severity < turbulence.severity) {
            [_currentTileAnotations setObject:turbulence forKey:tileAddressNew];
            
        }
        
    }
    long a = [[NSDate date] timeIntervalSince1970];
    NSLog(@"a - %ld",a - start);
    int x1 = 0;
    int y1 = 0;
    
    for ( Turbulence * turbulence in [_currentTileAnotations allValues]) {
        x1++;


        if (_pickerHistory.selectedItem+1 ==15 || [[NSDate date] timeIntervalSince1970] - turbulence.timestamp < (_pickerHistory.selectedItem+1) *6 * 3600) {
            
            
            
            
            int x = turbulence.tileX;
            int y = turbulence.tileY;
            int value = turbulence.severity;
            
            
            
            NSString * tileAddress = [NSString stringWithFormat:@"%@%@%@",[MapUtils padInt:x padTo:4],[MapUtils padInt:y padTo:4],@"11"];
            CLLocationCoordinate2D centerTileCoordinate = [MapUtils getCenterCoordinatesForTilePathForZoom:tileAddress];
            NSString * tileAddressNew = [MapUtils transformWorldCoordinateToTilePathForZoom:(int)zoomLevelForAnnotation.integerValue fromLon:centerTileCoordinate.longitude fromLat:centerTileCoordinate.latitude];
            centerTileCoordinate = [MapUtils getCenterCoordinatesForTilePathForZoom:tileAddressNew];
            
            
            y1++;
            RMAnnotation *annotation = [[RMAnnotation alloc] initWithMapView:self.map
                                                                  coordinate:centerTileCoordinate
                                                                    andTitle:@"turbulence"];
            
            annotation.userInfo = [NSNumber numberWithInt:value];
            [arr addObject:annotation];
        }
        
    }
    NSLog(@"%i/%i",y1,x1);
    long b = [[NSDate date] timeIntervalSince1970];
    NSLog(@"b - %ld",b - start);
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
        
        
        
        
        [self.map addAnnotations:arr];
        //update last server update
        long lastTurbulenceUpdateDate = (long)[[TurbulenceManager sharedManager]getSavedServerUpdateSince1970];
        if (lastTurbulenceUpdateDate == 0) {
            _lblLastUpdate.text =@"No data is available";
        } else {
            _lblLastUpdate.text =[NSString stringWithFormat:@"Updated @ %@",[Helpers getGMTTimeString:[NSDate dateWithTimeIntervalSince1970:lastTurbulenceUpdateDate] withFormat:@"dd/MM HH:mm"]];
        }
        
    }
    
    
    long end = [[NSDate date] timeIntervalSince1970];
    NSLog(@"end - %ld",end - start);
    
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

- (IBAction)btnFlightNumber_Clicked:(UIButton *)sender {
    if (_flightNumberViewController == nil) {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        _flightNumberViewController  = [sb instantiateViewControllerWithIdentifier:@"FlightNumber"];
    }
    _flightNumberPopover = [[UIPopoverController alloc] initWithContentViewController:_flightNumberViewController];
    _flightNumberPopover.popoverContentSize =  CGSizeMake(250.0, 100.0);
    _flightNumberPopover.backgroundColor = kColorToolbarBackground;
    _flightNumberViewController.view.backgroundColor = kColorToolbarBackground;
    
    if (self.presentedViewController) {
        [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    }
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        
        [_flightNumberPopover presentPopoverFromRect:sender.frame inView:self.viewRightMenu permittedArrowDirections:UIPopoverArrowDirectionRight animated:YES];
    }];
}

#pragma mark - timers

- (void) checkGoodLocation:(NSTimer *)incomingTimer
{
    //handle altitude scroller
    [self altitudeModeCycle];
    
    
    //update alertView
    [self setAlertViewAlerts];
    
    
    //    //remove old annotations
    //    for (RMAnnotation * annotation in _map.annotations) {
    //        if ([annotation.title isEqualToString:@"test"]) {
    //            [_map removeAnnotation:annotation];
    //        }
    //    }
    //
    //    NSString *  zoomLevelForAnnotation;
    //    int zoomFactor;
    //    switch ((int)_map.zoom) {
    //        case 6:
    //            zoomLevelForAnnotation =@"11";
    //            zoomFactor = pow(2,11);
    //            break;
    //        case 5:
    //            zoomLevelForAnnotation =@"11";
    //            zoomFactor = pow(2,11);
    //            break;
    //        case 4:
    //            zoomLevelForAnnotation =@"10";
    //            zoomFactor = pow(2,10);
    //            break;
    //        case 3:
    //            zoomLevelForAnnotation =@"09";
    //            zoomFactor = pow(2,9);
    //            break;
    //        case 2:
    //            zoomLevelForAnnotation =@"08";
    //            zoomFactor = pow(2,8);
    //            break;
    //        case 1:
    //        case 0:
    //            zoomLevelForAnnotation =@"08";
    //            zoomFactor = pow(2,8);
    //            break;
    //        default:
    //            break;
    //    }
    //
    //    for ( Turbulence * turbulence in array) {
    //        int x = turbulence.tileX;
    //        int y = turbulence.tileY;
    //        int value = 5;
    //
    //
    //
    //        NSString * tileAddress = [NSString stringWithFormat:@"%@%@%@",[MapUtils padInt:x padTo:4],[MapUtils padInt:y padTo:4],@"11"];
    //        CLLocationCoordinate2D centerTileCoordinate = [MapUtils getCenterCoordinatesForTilePathForZoom:tileAddress];
    //        NSString * tileAddressNew = [MapUtils transformWorldCoordinateToTilePathForZoom:(int)zoomLevelForAnnotation.integerValue fromLon:centerTileCoordinate.longitude fromLat:centerTileCoordinate.latitude];
    //        centerTileCoordinate = [MapUtils getCenterCoordinatesForTilePathForZoom:tileAddressNew];
    //
    //
    //        RMAnnotation *annotation = [[RMAnnotation alloc] initWithMapView:self.map
    //                                                              coordinate:centerTileCoordinate
    //                                                                andTitle:[Helpers getGMTTimeString:[NSDate dateWithTimeIntervalSince1970:turbulence.timestamp] withFormat:@"dd/MM HH:mm" ]];
    //
    //
    //        annotation.userInfo = [NSNumber numberWithInt:value];
    //
    //
    //
    //        annotation.title = @"test";
    //
    //
    //
    //        [self.map addAnnotation:annotation];
    //    }
    ///////////
    if ([LocationManager sharedManager].isLocationGood) {
        //update display
        _barItemGPS.tintColor = [UIColor whiteColor];
        CLLocation * currentLocation = [[LocationManager sharedManager] getCurrentLocation];
        bool isGoodGPS = [LocationManager sharedManager].isLocationGood;
        bool isGoodCourse = [LocationManager sharedManager].isHeadingGood;
        int currentAltitude = currentLocation.altitude * FEET_PER_METER;
        int currentVerticalAccuracy = currentLocation.verticalAccuracy * FEET_PER_METER;
        _BarItemTitle.title = [NSString stringWithFormat:@"Alt: %i Feet / Accuracy: %i Feet",currentAltitude,currentVerticalAccuracy];
        
        // if there is a valid course - draw Alert zone borders
        if ((isGoodCourse && isGoodGPS) || DEBUG_MODE) {
            [self drawAlertZoneBorders];
        } else {
            [self removeAlertZoneBorderAnnotations];
        }
    } else {
        
        //update display
        _barItemGPS.tintColor = [UIColor redColor];
        _BarItemTitle.title =@"Skypath";
        
        //remove alert zone border
        [self removeAlertZoneBorderAnnotations];
    }
}



#pragma mark - notification handling
-(void)turbuleceUpdatedFromServer:(NSNotification*)notification
{
    [_map removeAllAnnotations];
    [self addAnnotationsWithMap:_map];
}

-(void)newTurbulenceEvent:(NSNotification*)notification
{
    NSLog(@"New Turbulence event");
    Turbulence * turbulence = notification.object;
    _viewTurbulence.backgroundColor = [self getColorForSeverity:turbulence.severity];
    _viewTurbulence.hidden = false;
    
    _timerHideTurbulenceMarker = [NSTimer scheduledTimerWithTimeInterval:4 target:self selector:@selector(hideTurbulenceMarker:) userInfo:nil repeats:NO];
}

-(void)deviceInMotion:(NSNotification *) notification
{
    _imageShake.hidden=false;
}

-(void)deviceStatic:(NSNotification *) notification
{
    _imageShake.hidden=true;
}

-(void)flightNumberChanged:(NSNotification *) notification
{
    [_btnFlightNumber setTitle:[[NSUserDefaults standardUserDefaults]objectForKey:@"flightNumber"]  forState:UIControlStateNormal]  ;
}

-(void) locationStatusChanged:(NSNotification *) notification {
    
    NSString * str = notification.object;
    bool isGoodLocation = [str boolValue];
    //location status changed so we ned to replace Icon
    
    for (RMAnnotation * annotation in _map.annotations) {
        if (annotation.isUserLocationAnnotation) {
            for (RMMapLayer * layer in annotation.layer.sublayers) {
                if ([layer.name isEqualToString:@"airplane"]) {
                    layer.opacity=0;
                    if (isGoodLocation ) {
                        layer.opacity =1;
                    }
                }
                
            }
            
        }
        if ([annotation.title isEqualToString:@"AlertZoneBorder"]) {
            if (!isGoodLocation ) [_map removeAnnotation:annotation];
        }
    };
}

-(void) headingStatusChanged:(NSNotification *) notification {
    NSString * str = notification.object;
    bool isGoodLocation = [str boolValue];
    //heading status changed so we need to replace Icon
    
    for (RMAnnotation * annotation in _map.annotations) {
        if (annotation.isUserLocationAnnotation) {
            for (RMMapLayer * layer in annotation.layer.sublayers) {
                if ([layer.name isEqualToString:@"airplane"]) {
                    layer.opacity=0;
                    if (isGoodLocation ) {
                        layer.opacity =1;
                    }
                }
                
            }
            
        }
        if ([annotation.title isEqualToString:@"AlertZoneBorder"]) {
            if (!isGoodLocation ) [_map removeAnnotation:annotation];
        }
    };
}

-(void)locationChanged:(NSNotification *)notification {
    
}

-(void)invalidToken:(NSNotification *) notification {
    //bad token - logout
    [self performSegueWithIdentifier:@"segueUnwind" sender:self];
    
}

#pragma mark - Alert Zone Border
-(void)drawAlertZoneBorders {
    CLLocation * currentLocation = [[LocationManager sharedManager] getCurrentLocation];
    if (currentLocation) {
        
        
        NSMutableArray * locations =[NSMutableArray new];
        [locations addObject:currentLocation];
        
        for (int az = -kAlertAngle; az<=kAlertAngle; az+=5) {
            double currentCalcCourse =currentLocation.course + az;
            //correct to 0-359
            if (currentCalcCourse >=360) currentCalcCourse -= 360;
            if (currentCalcCourse <=0) currentCalcCourse=360 + currentCalcCourse;
            CLLocationCoordinate2D coord = [MapUtils NewLocationFrom:currentLocation.coordinate atDistanceInMiles:kAlertRange alongBearingInDegrees:currentCalcCourse];
            // Create a coordinates array to all of the coordinates for our shape.
            [locations addObject: [[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude]];
            
        }
        [locations addObject:currentLocation];
        
        
        
        //remove old Alert Zone Border annotations
        [self removeAlertZoneBorderAnnotations];
        
        
        //add new Alert Zone Border annotations
        
        
        
        
        // Create our shape with the formatted coordinates array
        RMAnnotation *annotation = [[RMAnnotation alloc] initWithMapView:_map
                                                              coordinate:currentLocation.coordinate
                                                                andTitle:@"AlertZoneBorder"];
        
        annotation.userInfo = locations;
        [annotation setBoundingBoxFromLocations:locations];
        
        // Add the shape to the map
        [_map addAnnotation:annotation];
    }
}

-(void) removeAlertZoneBorderAnnotations {
    for (RMAnnotation * annotation in _map.annotations) {
        if ([annotation.title isEqualToString:@"AlertZoneBorder"]) {
            [_map removeAnnotation:annotation];
        }
    };
}




#pragma mark -

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self userLocationModeChanged];
}

#pragma mark ------------------------

-(void)hideTurbulenceMarker:(NSTimer*)timer
{
    _viewTurbulence.hidden=true;
}

#pragma mark - misc
-(UIColor *)getColorForSeverity:(int) severity
{
    
    switch (severity) {
        case 0:
            return kColorNone;
            break;
        case 1:
            return kColorLight;
            break;
        case 2:
            return kColorLightModerate;
            break;
        case 3:
            return kColorModerate;
            break;
        case 4:
            return kColorModerateSevere;
            break;
        case 5:
            return kColorSevere;
            break;
        default:
            return nil;
            break;
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark - about view delegate
-(void) logout {
    [_aboutPopover dismissPopoverAnimated:NO];
    _aboutPopover = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_map removeObserver:self forKeyPath:@"userTrackingMode"];
    [_timerAltitudeReturnToAuto invalidate];
    [_timerGpsSignal invalidate];
    [_timerAlertSound invalidate];
    [_timerHideTurbulenceMarker  invalidate];
    _pickerHistory = nil;
    _avSound =nil;
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

- (IBAction)btnSwap_Clicked:(UIButton *)sender {
    [[RouteManager sharedManager] swapAirportOriginDestination];
    _lblTakoff.text = [RouteManager sharedManager].currentFlight.originAirport.ICAO;
    _lblLand.text = [RouteManager sharedManager].currentFlight.destinationAirport.ICAO;
    [_map removeAllAnnotations];
    [self addAnnotationsWithMap:_map];
    
}
- (IBAction)btnUserLocation_Click:(UIBarButtonItem *)sender {
    if (_map.userTrackingMode == RMUserTrackingModeFollow) {
        [_map setUserTrackingMode:RMUserTrackingModeFollowWithHeading animated:YES] ;
        
    } else if (_map.userTrackingMode == RMUserTrackingModeFollowWithHeading){
        [_map setUserTrackingMode:RMUserTrackingModeNone animated:YES] ;
        
    } else {
        [_map setUserTrackingMode:RMUserTrackingModeFollow animated:YES] ;
    }
    [self userLocationModeChanged];
}

-(void) userLocationModeChanged {
    if (_map.userTrackingMode == RMUserTrackingModeFollow) {
        _barItemUserLocation.tintColor = [UIColor greenColor];
    } else if (_map.userTrackingMode == RMUserTrackingModeFollowWithHeading){
        _barItemUserLocation.tintColor = [UIColor orangeColor];
    } else {
        _barItemUserLocation.tintColor = [UIColor whiteColor];
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
    return kAltitude_NumberOfSteps  ;
}


// Catpure the picker view selection
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    bool isNewPick = false;
    if (_isShouldShowAutoScroll) {
        if (_selectedAltitudeLayer !=kAltitude_NumberOfSteps - (int)row) {
            _selectedAltitudeLayer = kAltitude_NumberOfSteps - (int)row;
            _selectedALtitudeDelta =  _selectedAltitudeLayer -_currentAltitudeLevel;
            
            //set timer to return to auto hight in 3 minutes
            [_timerAltitudeReturnToAuto invalidate];
            _timerAltitudeReturnToAuto = [NSTimer scheduledTimerWithTimeInterval:3*60 target:self selector:@selector(returnToAutoAltitude:) userInfo:nil repeats:NO];
            isNewPick=true;
        }

    } else {
        if (_selectedAltitudeLayer !=(int)row +1) {
            _selectedAltitudeLayer = (int)row +1;
            isNewPick=true;
        }
        
    }
    if (isNewPick) {
        [self.map removeAllAnnotations];
        [self addAnnotationsWithMap:self.map];
    }

}
- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view{
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, pickerView.frame.size.width, 20)];
    label.backgroundColor = [UIColor grayColor];
    label.textColor = [UIColor whiteColor];
    label.textAlignment= NSTextAlignmentCenter;
    label.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20];
    if (!_isShouldShowAutoScroll) {
        label.text = [NSString stringWithFormat:@"%i-%i", (int)(kAltitude_Min+row * kAltitude_Step),(int)(kAltitude_Min+(row+1) * kAltitude_Step)];
    } else {
        row = kAltitude_NumberOfSteps - row;
        long level = labs((_currentAltitudeLevel - row )* kAltitude_Step);
        NSString * strlevel;
        
        if (row < _currentAltitudeLevel) {
            strlevel = [NSString stringWithFormat:@"-%ld",level];
        } else if (row > _currentAltitudeLevel) {
            strlevel = [NSString stringWithFormat:@"+%ld",level];
        } else {
            strlevel = @"Auto";
        }
        
        label.text = strlevel;
    }
    
    
    return label;
}


- (IBAction)switchAltitudeAuto_changed:(UISwitch *)sender {
    [self altitudeModeCycle];
}



-(void)returnToAutoAltitude:(NSTimer *) timer {
    [_timerAltitudeReturnToAuto invalidate];
    _timerAltitudeReturnToAuto = nil;
    _selectedALtitudeDelta=0;
    [_pickerAltitude selectRow:(kAltitude_NumberOfSteps - _currentAltitudeLevel) inComponent:0 animated:YES];
    _selectedAltitudeLayer =  _currentAltitudeLevel;
    [_map removeAllAnnotations];
    [self addAnnotationsWithMap:_map];
}


#pragma mark - AKPickerViewDelegate

- (NSUInteger)numberOfItemsInPickerView:(AKPickerView *)pickerView
{
    return 15;
}

/*
 * AKPickerView now support images!
 *
 * Please comment '-pickerView:titleForItem:' entirely
 * and uncomment '-pickerView:imageForItem:' to see how it works.
 *
 */

- (NSString *)pickerView:(AKPickerView *)pickerView titleForItem:(NSInteger)item
{
    if (item+1==15) {
        return @"ALL";
    }
    return [NSString stringWithFormat:@"%ih", (int)(6 * (item+1))];
}

/*
 - (UIImage *)pickerView:(AKPickerView *)pickerView imageForItem:(NSInteger)item
 {
	return [UIImage imageNamed:self.titles[item]];
 }
 */


- (void)pickerView:(AKPickerView *)pickerView didSelectItem:(NSInteger)item
{
    [_map removeAllAnnotations];
    [self addAnnotationsWithMap:_map];
    
    //set alert cutoff time
    if (_pickerHistory.selectedItem+1 ==15) {
        [[AlertsManager sharedManager] setCutOffTime:24000 * 3600];
    }
    else  {
        [[AlertsManager sharedManager] setCutOffTime:(_pickerHistory.selectedItem+1) *6 * 3600];
    }
    
}

#pragma mark - scroll states
-(void) setManualMode {
    _altitudeModeState=ZLAltitudeModeManual;
    NSLog(@"set manual mode");
    float alt = [[LocationManager sharedManager] getCurrentLocation].altitude * FEET_PER_METER;
    NSLog(@"%f",alt);
    _currentAltitudeLevel = [[LocationManager sharedManager] getCurrentTile].altitude;
    _selectedAltitudeLayer =  _currentAltitudeLevel;
    
    //hide auto scroll and set switch to off
    _viewAutoAltutude.hidden = true;
    [_switchAltitudeAuto setOn:false];
    
    //if we moved from state that showed auto scroll then switch to manual scroll
    if (_isShouldShowAutoScroll) {
        //set manual scroll view is needed
        _isShouldShowAutoScroll=false;
        
        //build scroller and set its auto to current level
        [_pickerAltitude reloadAllComponents];
        [_pickerAltitude selectRow:_currentAltitudeLevel-1 inComponent:0 animated:YES];
        
        //reload view
        [_map removeAllAnnotations];
        [self addAnnotationsWithMap:_map];
    }
    
    
}
-(void) setAutoMode {
    NSLog(@"set auto mode");
    _altitudeModeState=ZLAltitudeModeAuto;
    _currentAltitudeLevel = [[LocationManager sharedManager] getCurrentTile].altitude;
    _selectedAltitudeLayer =  _currentAltitudeLevel;
    
    //show auto scroll and set switch to on
    _viewAutoAltutude.hidden = false;
    [_switchAltitudeAuto setOn:true];
    
    //set auto scroll view is needed
    _isShouldShowAutoScroll=true;
    
    //build scroller and set its auto to current level
    [_pickerAltitude reloadAllComponents];
    int rowToShow = kAltitude_NumberOfSteps - (_currentAltitudeLevel +_selectedALtitudeDelta);
    if (rowToShow <0) rowToShow =  0;
    if (rowToShow > kAltitude_NumberOfSteps) rowToShow =  kAltitude_NumberOfSteps;
    //    [_pickerAltitude selectRow:(kAltitude_NumberOfSteps - _currentAltitudeLevel) inComponent:0 animated:YES];
    [_pickerAltitude selectRow:rowToShow inComponent:0 animated:YES];
    
    //reload view
    [_map removeAllAnnotations];
    [self addAnnotationsWithMap:_map];
    
    
}
-(void) setAutoSuspendedMode {
    _altitudeModeState = ZLAltitudeModeAutoSuspended;
    NSLog(@"set auto suspended mode");
    
    _currentAltitudeLevel = [[LocationManager sharedManager] getCurrentTile].altitude;
    _selectedAltitudeLayer =  _currentAltitudeLevel;
    
    //hide auto scroll
    _viewAutoAltutude.hidden = true;
    
    //set manual scroll view is needed
    _isShouldShowAutoScroll=false;
    
    //build scroller and set its auto to current level
    [_pickerAltitude reloadAllComponents];
    [_pickerAltitude selectRow:_currentAltitudeLevel-1 inComponent:0 animated:YES];
    
    //reload view
    [_map removeAllAnnotations];
    [self addAnnotationsWithMap:_map];
    
    //invalidate timer
    [_timerAltitudeReturnToAuto invalidate];
    
}
-(void) setAutoUserSuspendedMode {
    NSLog(@"set autoUser suspended mode");
    _altitudeModeState = ZLAltitudeModeAutoUserSuspended;
    
    _currentAltitudeLevel = [[LocationManager sharedManager] getCurrentTile].altitude;
    _selectedAltitudeLayer =  _currentAltitudeLevel;
    
    //show auto scroll
    _viewAutoAltutude.hidden = false;
    
    if (_isShouldShowAutoScroll) {
        
        //set manual scroll view is needed
        _isShouldShowAutoScroll=false;
        
        //build scroller and set its auto to current level
        [_pickerAltitude reloadAllComponents];
        [_pickerAltitude selectRow:_currentAltitudeLevel-1 inComponent:0 animated:YES];
        
        //reload view
        [_map removeAllAnnotations];
        [self addAnnotationsWithMap:_map];
        
        //invalidate timer
        [_timerAltitudeReturnToAuto invalidate];
        
    }
}
-(void) setAutoUserSuspendedBadGpsMode {
    NSLog(@"set autoUser suspended bad Gps mode");
    _altitudeModeState = ZLAltitudeModeAutoUserSuspendedBadGps;
    
    //hide auto scroll
    _viewAutoAltutude.hidden = true;
    
}



-(void)altitudeModeCycle {
    int altitudeLevel = [[LocationManager sharedManager] getCurrentTile].altitude ;
    bool isGoodLocation = [LocationManager sharedManager].isLocationGood ;
    float altitude = [[LocationManager sharedManager] getCurrentLocation].altitude * FEET_PER_METER;
    
    
    switch (_altitudeModeState) {
            
        case ZLAltitudeModeManual:
            //if altitude above kAltitude_MoveToAutoAltitudeMode - switch to auto alt mode
            if (altitude > kAltitude_MoveToAutoAltitudeMode * 1000) {
                [self setAutoMode];
                return;
            }
            
            break;
            
        case ZLAltitudeModeAuto:
            //if altitude below kAltitude_MoveToAutoAltitudeMode - switch to manual alt mode
            if (altitude < kAltitude_MoveToAutoAltitudeMode * 1000 - 100) {
                _selectedALtitudeDelta=0;
                [self setManualMode];
                return;
            }
            //if user switch off - switch to auto USER suspended mode
            if (!_switchAltitudeAuto.isOn) {
                _selectedALtitudeDelta=0;
                [self setAutoUserSuspendedMode];
                return;
            }
            //if bad GPS  switch to auto suspended mode
            if (!isGoodLocation) {
                [self setAutoSuspendedMode];
                return;
            }
            
            //if no state change
            //if level changed
            if (_currentAltitudeLevel!=altitudeLevel) {
                //set new level
                _currentAltitudeLevel = altitudeLevel;
                _selectedAltitudeLayer =  _currentAltitudeLevel;
                
                //build scroller and set its auto to current level
                [_pickerAltitude reloadAllComponents];
                int rowToShow = kAltitude_NumberOfSteps - (_currentAltitudeLevel +_selectedALtitudeDelta);
                if (rowToShow <0) rowToShow =  0;
                if (rowToShow > kAltitude_NumberOfSteps) rowToShow =  kAltitude_NumberOfSteps;
                
                
                [_pickerAltitude selectRow:rowToShow inComponent:0 animated:YES];
                
                //reload view
                [_map removeAllAnnotations];
                [self addAnnotationsWithMap:_map];
            }
            
            
            break;
        case ZLAltitudeModeAutoSuspended:
            //if altitude above kAltitude_MoveToAutoAltitudeMode and GOOD GPS- switch to auto mode
            if ((altitude > kAltitude_MoveToAutoAltitudeMode * 1000) && isGoodLocation ) {
                [self setAutoMode];
            }
            //if altitude below kAltitude_MoveToAutoAltitudeMode - switch to manual mode
            if (altitude < kAltitude_MoveToAutoAltitudeMode * 1000 - 100 ) {
                [self setManualMode];
            }
            //if bad GPS stay in auto suspended - nothing to do
            
            break;
            
            
        case ZLAltitudeModeAutoUserSuspended:
            //if altitude below kAltitude_MoveToAutoAltitudeMode - switch to manual mode
            if (altitude < kAltitude_MoveToAutoAltitudeMode * 1000 - 100 ) {
                [self setManualMode];
            }
            //if user switch on and good gps - switch to auto mode
            if (_switchAltitudeAuto.isOn && isGoodLocation) {
                [self setAutoMode];
            }
            //if bad gps - switch to auto suspended mode
            if (!isGoodLocation) {
                [self setAutoUserSuspendedBadGpsMode];
            }
            
            break;
            
        case ZLAltitudeModeAutoUserSuspendedBadGps:
            //if altitude below kAltitude_MoveToAutoAltitudeMode - switch to manual mode
            if (altitude < kAltitude_MoveToAutoAltitudeMode * 1000 - 100 ) {
                [self setManualMode];
            }
            //if good gps - switch to auto Suspended mode
            if ( isGoodLocation) {
                [self setAutoUserSuspendedMode];
            }
            
            
            break;
        default:
            break;
    }
}

#pragma mark - Alert Delagate and alert methodes
-(void)alertStateChanged:(ZLAlertState)newState {
    switch (newState) {
        case ZLAlert_NoAlerts:
            _viewAlertView.hidden = true;
            _btnAlertSilence.hidden =true;
            [self unBlinkAlertView];
            [_avSound stop];
            if (_timerAlertSound) {
                [_timerAlertSound invalidate];
            }
            
            break;
            
        case ZLAlert_NewAlert:
            _viewAlertView.hidden = false;
            [_btnAlertSilence setTitle:@"Silence" forState:UIControlStateNormal];
            _btnAlertSilence.hidden =false;
            _btnAlertSilence.enabled =true;
            _lblAlertViewHeader.text = @"Turbulence Ahead";
            _lblAlertViewHeader.textColor = [UIColor whiteColor] ;
            [self blinkAlertView];
            [_avSound play];
            [self timerAlertSoundStart:nil];
            
            
            break;
        case  ZLAlert_NewAlertNoGPS:
            _viewAlertView.hidden = false;
            [_btnAlertSilence setTitle:@"Reset" forState:UIControlStateNormal];
            _btnAlertSilence.hidden =false;
            _btnAlertSilence.enabled =true;
            _lblAlertViewHeader.text = @"No GPS - showing last date";
            _lblAlertViewHeader.textColor = [UIColor redColor] ;
            break;
            
        case ZLAlert_UserAccepted:
            _viewAlertView.hidden = false;
            _btnAlertSilence.hidden =true;
            _lblAlertViewHeader.text = @"Turbulence Ahead";
            _lblAlertViewHeader.textColor = [UIColor whiteColor] ;
            [self unBlinkAlertView];
            [_avSound stop];
            [_timerAlertSound invalidate];
            \
            break;
        case ZLAlert_UserAcceptedNoGPS:
            _viewAlertView.hidden = false;
            [_btnAlertSilence setTitle:@"Reset" forState:UIControlStateNormal];
            _btnAlertSilence.hidden =false;
            _btnAlertSilence.enabled =true;
            _lblAlertViewHeader.text = @"No GPS - showing last date";
            _lblAlertViewHeader.textColor = [UIColor redColor] ;
            break;
        default:
            break;
    }
    [self setAlertViewAlerts];
}

-(void) setAlertViewAlerts {
    
    _viewAlertAbove.backgroundColor = [self getColorForSeverity:[AlertsManager sharedManager].altAboveAlert];
    _viewAlertCurrentAlt.backgroundColor = [self getColorForSeverity:[AlertsManager sharedManager].altCurrentAlert];
    _viewAlertBelow.backgroundColor = [self getColorForSeverity:[AlertsManager sharedManager].altBelowAlert];
}

- (IBAction)btnSilence_Clicked:(id)sender {
    if ([_btnAlertSilence.titleLabel.text isEqualToString:@"Silence"]) {
        [[AlertsManager sharedManager] userAccepted];
    } else {
        [[AlertsManager sharedManager] userReset];
    }
    
}

-(void) blinkAlertView {
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    [animation setFromValue:[NSNumber numberWithFloat:1.0]];
    [animation setToValue:[NSNumber numberWithFloat:0.5]];
    [animation setDuration:0.5f];
    [animation setTimingFunction:[CAMediaTimingFunction
                                  functionWithName:kCAMediaTimingFunctionLinear]];
    [animation setAutoreverses:YES];
    [animation setRepeatCount:20000];
    [[_viewAlertView layer] addAnimation:animation forKey:@"opacity"];
}
-(void) unBlinkAlertView {
    [[_viewAlertView layer] removeAllAnimations];
}

-(void) timerAlertSoundStart:(NSTimer *) timer {
    [self registerLocalPush];
    [self sendAlertNotification];
    _timerAlertSound = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self
                                                      selector:@selector(timerAlertSoundStart:) userInfo:nil repeats:NO];
    [_avSound play];
}

-(void) registerLocalPush {
    UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
    UIUserNotificationSettings *mySettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
}

-(void)sendAlertNotification {
    UILocalNotification* localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:0];
    localNotification.alertBody = @"Turbulence Ahead ! \n Caution !";
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}


@end
