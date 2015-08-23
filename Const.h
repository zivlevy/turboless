//
//  Const.h
//  TurboMaps
//
//  Created by Ziv Levy on 8/17/15.
//  Copyright (c) 2015 ZivApps. All rights reserved.
//

#ifndef TurboMaps_Const_h
#define TurboMaps_Const_h


#define DEBUG_MODE 0

#define kBaseURL @"http://104.197.5.131:3000"
//#define kBaseURL @"http://84.94.182.244:3000"
#define FEET_PER_METER 3.28084

#define kColorLight [Helpers r:2 g:115 b:1 alpha:1.0]
#define kColorLightModerate [Helpers r:197 g:194 b:9 alpha:1.0]
#define kColorModerate [Helpers r:190 g:73 b:2 alpha:1.0]
#define kColorSevere [Helpers r:127 g:0 b:0 alpha:1.0]
#define kColorExtream [Helpers r:97 g:0 b:151 alpha:1.0]

#define kAltitude_Min 10
#define kAltitude_NumberOfSteps 15
#define kAltitude_Step 2

//UIColors
#define kColorViewBackground [Helpers r:39 g:40 b:44 alpha:1.0]
#define kColorToolbarBackground [Helpers r:39 g:44 b:54 alpha:1.0]
//notifications
#define kNotification_turbulenceServerNewFile @"turbulenceServerNewFile"
#define kNotification_IOSAccelerometerDataRecieved @"IOSAccelerometerDataRecieved"
#define kNotification_LocationStatusChanged @"LocationStatusChanged"

#define kNotification_TurbulenceEvent @"TurbulenceEvent"
#define kNotification_DeviceInMotion @"DeviceInMotion"
#define kNotification_DeviceInStatic @"DeviceInStatic"

#endif
