//
//  TurbulenceManager.h
//  TurboMaps
//
//  Created by Ziv Levy on 8/18/15.
//  Copyright (c) 2015 ZivApps. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TurbulenceManager : NSObject
+ (TurbulenceManager *)sharedManager;

//public
-(NSDictionary *) getTurbulanceDictionaryArLevel:(int)level;
-(long long) getSavedServerUpdateSince1970;
@end
