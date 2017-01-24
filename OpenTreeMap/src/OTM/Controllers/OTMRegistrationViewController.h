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
#import "OTMScrollAwareViewController.h"
#import "OTMValidator.h"
#import "OTMPictureTaker.h"

@class OTMEULAViewController;

@interface OTMRegistrationViewController : OTMScrollAwareViewController<UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic,readonly) OTMValidator *validator;
@property (nonatomic,readonly) OTMPictureTaker *pictureTaker;

@property (nonatomic,strong) IBOutlet UITextField *email;
@property (nonatomic,strong) IBOutlet UITextField *password;
@property (nonatomic,strong) IBOutlet UITextField *verifyPassword;
@property (nonatomic,strong) IBOutlet UITextField *username;
@property (nonatomic,strong) IBOutlet UITextField *firstName;
@property (nonatomic,strong) IBOutlet UITextField *lastName;
@property (nonatomic,strong) IBOutlet UITextField *zipCode;
@property (nonatomic,strong) IBOutlet UIImageView *profileImage;
@property (nonatomic,strong) IBOutlet UIButton *changeProfilePic;
@property (nonatomic,strong) OTMEULAViewController *eulaController;

-(IBAction)getPicture:(id)sender;
-(IBAction)validateAndShowEULA:(id)sender;
-(void)createNewUser;

@end
