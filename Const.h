//
//  Const.h
//  TurboMaps
//
//  Created by Ziv Levy on 8/17/15.
//  Copyright (c) 2015 ZivApps. All rights reserved.
//

#ifndef TurboMaps_Const_h
#define TurboMaps_Const_h

typedef struct {
    int x;
    int y;
    int altitude;
} ZLTile;

#define DEBUG_MODE 1
//#define kBaseURL @"http://84.94.182.244:3000" //yuval home

#define kBaseURL @"http://104.197.5.131:3000"
#define FEET_PER_METER 3.28084

#define kColorNone [Helpers r:255 g:255 b:255 alpha:0.8]
//#define kColorLight [Helpers r:2 g:115 b:1 alpha:1.0]
//#define kColorLightModerate [Helpers r:34 g:127 b:255 alpha:1.0]
#define kColorLight [Helpers r:14 g:255 b:0 alpha:1.0]
#define kColorLightModerate [Helpers r:242 g:255 b:12 alpha:1.0]
#define kColorModerate  [Helpers r:255 g:166 b:0 alpha:1.0]
#define kColorModerateSevere [Helpers r:250 g:0 b:0 alpha:1.0]
#define kColorSevere [Helpers r:255 g:0 b:195 alpha:1.0]

#define kAltitude_Min 10
#define kAltitude_NumberOfSteps 16
#define kAltitude_Step 2
#define kAltitude_MoveToAutoAltitudeMode 20
#define kAltitude_InitialAltitudeForPicker 30

//UIColors
#define kColorViewBackground [Helpers r:39 g:40 b:44 alpha:1.0]
#define kColorToolbarBackground [Helpers r:39 g:44 b:54 alpha:1.0]
//notifications
#define kNotification_turbulenceServerNewFile @"turbulenceServerNewFile"
#define kNotification_IOSAccelerometerDataRecieved @"IOSAccelerometerDataRecieved"
#define kNotification_LocationStatusChanged @"LocationStatusChanged"
#define kNotification_HeadingStatusChanged @"HeadingStatusChanged"
#define kNotification_NewGPSLocation @"NewGPSLocation"

#define kNotification_TurbulenceEvent @"TurbulenceEvent"
#define kNotification_TurbulenceEventWrittenToFile @"TurbulenceEventWrittenToFile"
#define kNotification_DeviceInMotion @"DeviceInMotion"
#define kNotification_DeviceInStatic @"DeviceInStatic"

#define kNotification_FlightNumberChanged @"FlightNumberChanged"

#define kNotification_InvalidToken @"InvalidToken"

//Alert
#define kAlertRange 100
#define kAlertAngle 15
#define kAlertSeverityForAlert 1 //start alerting from moderate
#endif
