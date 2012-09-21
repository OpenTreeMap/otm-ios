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
#import "OTMUser.h"
#import "OTMScrollAwareViewController.h"

@class OTMLoginViewController;
@class OTMLoginManager;

@protocol OTMLoginManagerDelegate <NSObject>

-(void)loginController:(OTMLoginViewController*)vc loggedInWithUser:(OTMUser*)user;
-(void)loginControllerCanceledLogin:(OTMLoginViewController*)vc;
-(void)loginController:(OTMLoginViewController*)vc registeredUser:(OTMUser*)user;

@end

@interface OTMLoginViewController : OTMScrollAwareViewController

@property (nonatomic,weak) id<OTMLoginManagerDelegate> loginDelegate;
@property (nonatomic,strong) IBOutlet UITextField *username;
@property (nonatomic,strong) IBOutlet UITextField *password;

-(IBAction)attemptLogin:(id)sender;

@end
