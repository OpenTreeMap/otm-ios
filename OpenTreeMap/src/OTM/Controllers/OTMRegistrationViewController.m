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

#import "OTMRegistrationViewController.h"
#import "OTMAppDelegate.h"

@interface OTMRegistrationViewController ()

+(NSArray *)validations;

@end

@implementation OTMRegistrationViewController

@synthesize email, password, verifyPassword, firstName, lastName, profileImage, zipCode, username, changeProfilePic, validator, pictureTaker;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}                                                    
              
+(NSArray *)validations {
    OTMValidatorValidation verifyPW = [^(OTMRegistrationViewController* vc) {
        if (![vc.password.text isEqualToString:vc.verifyPassword.text]) {
            return @"Passwords must match";
        } else {
            return (NSString *)nil;
        }
    } copy];
    
    OTMValidatorValidation verifyEmail = [OTMTextFieldValidator emailValidation:@"email"
                                                               display:@"Email"];
    
    OTMValidatorValidation pwMinLength = [OTMTextFieldValidator minLengthValidation:@"password"
                                                                   display:@"Password"
                                                                 minLength:6];
    
    OTMValidatorValidation usernameNotBlank = [OTMTextFieldValidator notBlankValidation:@"username"
                                                                       display:@"Username"];
    
    OTMValidatorValidation zipcode = [OTMValidator validation:[OTMTextFieldValidator lengthValidation:@"zipCode"
                                                                                     display:@"Your zip code"
                                                                                      length:5]
                                                           or:[OTMTextFieldValidator isBlankValidation:@"zipCode"
                                                                                      display:@""]
                                                      display:@"Your zip code must be 5 digits or empty"];
    
    return [NSArray arrayWithObjects:verifyPW, verifyEmail, pwMinLength, usernameNotBlank, zipcode, nil];
}



//TODO: Validations

-(void)registrationSuccess:(OTMUser *)user {
    [[NSNotificationCenter defaultCenter] postNotificationName:kOTMLoginWorkflowUserRegistered
                                                        object:user];    
}

-(void)savePhoto:(OTMUser *)user {
    [[[OTMEnvironment sharedEnvironment] api] setProfilePhoto:user
                                                     callback:^(id json, NSError *error) 
     {
         if (error != nil) {
             [[[UIAlertView alloc] initWithTitle:@"Server Error"
                                         message:@"There was a server error"
                                        delegate:nil
                               cancelButtonTitle:@"OK"
                               otherButtonTitles:nil] show];
         } else {
             [self registrationSuccess:user];
         }
     }];
}

-(IBAction)createNewUser:(id)sender {
    if ([self.validator executeValidationsAndAlertWithViewController:self]) {
        OTMUser *user = [[OTMUser alloc] init];
        user.keychain = [SharedAppDelegate keychain];
        user.username = self.username.text;
        user.password = self.password.text;
        user.firstName = self.firstName.text;
        user.lastName = self.lastName.text;
        user.email = self.email.text;
        user.zipcode = self.zipCode.text;
        user.photo = self.profileImage.image;
        
        [[[OTMEnvironment sharedEnvironment] api] createUser:user
                                                   callback:^(OTMUser *user, OTMAPILoginResponse status) 
        {
            if (status == kOTMAPILoginResponseOK) {
                if (user.photo != nil) {
                    [self savePhoto:user];
                } else {
                    [self registrationSuccess:user];
                }
            } else if (status == kOTMAPILoginDuplicateUsername) {
                [self.username becomeFirstResponder];
                [self.username selectAll:self];
                NSString *message = [NSString stringWithFormat:@"The username %@ is already reistered. Tap 'Login' and enter your password for this username or choose a different username.", self.username.text];
                [[[UIAlertView alloc] initWithTitle:@"Already Registered"
                                            message:message
                                           delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil] show];
            } else {
                [[[UIAlertView alloc] initWithTitle:@"Registration Failed"
                                           message:@"A server problem prevented your registration from completing. Please try again later."
                                          delegate:nil
                                 cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil] show];
            }
        }];
    }
}

//overrides OTMScrollAwareVC
-(IBAction)completedForm:(id)sender {
    if (self.profileImage.image == nil) {
        [UIAlertView showAlertWithTitle:@"Add Profile Picture"
                                message:@"Would you like to select a profile picture?"
                      cancelButtonTitle:@"No"
                       otherButtonTitle:@"Yes"
                               callback:^(UIAlertView* alertview, int btnIdx) 
        {
            // This gets around a weird bug where showing the picker while
            // the alert view is already up yields a weird state where
            // touch events do not register
            dispatch_async(dispatch_get_main_queue(), ^{
                if (btnIdx == 0) { // NO
                    [self createNewUser:nil];
                } else {
                    [pictureTaker getPictureInViewController:self
                                                    callback:^(UIImage *image) 
                     {
                         if (image) {
                             self.profileImage.image = image;
                             
                             [self.changeProfilePic setTitle:@"Update Profile Picture"
                                                    forState:UIControlStateNormal];                                                  
                         }
                     }];
                }
            });
        }];
    }
}

-(IBAction)getPicture:(id)sender {
    [pictureTaker getPictureInViewController:self
                                    callback:^(UIImage *image) 
     {
         if (image) {
             self.profileImage.image = image;                                                 
         }
     }];    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (validator == nil) {
        validator = [[OTMValidator alloc] initWithValidations:[OTMRegistrationViewController validations]];
    }
    if (pictureTaker == nil) {
        pictureTaker = [[OTMPictureTaker alloc] init];
    }
    
    self.scrollView.contentSize = CGSizeMake(320, 460);
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
