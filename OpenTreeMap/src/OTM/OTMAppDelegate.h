//
//  OTMAppDelegate.h
//  OpenTreeMap
//
//  Created by Robert Cheetham on 2/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "AZKeychainItemWrapper.h"
#import "OTMLoginManager.h"

#define kOTMChangeMapModeNotification @"kOTMChangeMapModeNotification"

@interface OTMAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic,strong) AZKeychainItemWrapper *keychain;
@property (nonatomic,strong) OTMLoginManager* loginManager;
@property (nonatomic,assign) MKCoordinateRegion mapRegion;

/*
 Used to help keep the modes of multiple map views in sync. Views that
 are already loaded stay in sync with an NSNotification, but a view that
 is lazy loaded needs to get an initial value from somewhere.
 */
@property (nonatomic,assign) NSInteger mapMode;

@end
