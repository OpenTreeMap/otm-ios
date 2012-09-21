// This file is part of the OpenTreeMap code.
//
// OpenTreeMap is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// OpenTreeMap is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with OpenTreeMap.  If not, see <http://www.gnu.org/licenses/>.

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
