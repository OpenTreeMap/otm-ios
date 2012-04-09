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

@interface OTMAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic,strong) AZKeychainItemWrapper *keychain;
@property (nonatomic,strong) OTMLoginManager* loginManager;
@property (nonatomic,assign) MKCoordinateRegion mapRegion;

@end
