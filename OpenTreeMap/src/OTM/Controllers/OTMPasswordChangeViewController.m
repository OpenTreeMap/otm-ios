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

#import "OTMPasswordChangeViewController.h"

@interface OTMPasswordChangeViewController ()

@end

@implementation OTMPasswordChangeViewController

@synthesize validator, oldPassword, aNewPassword, aNewPasswordVerify;

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.screenName = @"Change Password";  // for Google Analytics

    OTMValidatorValidation equalsValidation = [^(OTMPasswordChangeViewController *vc) {
        if (![vc.aNewPassword.text isEqualToString:vc.aNewPasswordVerify.text]) {
            return @"Password and password confirmation must match";
        } else {
            return (NSString *)nil;
        }
    } copy];
    
    // Note that we should never actually get to this validation
    // nor would we be able to change it, but just in case this provides a user
    // friendly message
    OTMValidatorValidation requiresLogin = [^(OTMPasswordChangeViewController *vc) {
        OTMUser *user = [SharedAppDelegate loginManager].loggedInUser;
        
        if (user == nil) {
            return @"You must be logged in to change your password";
        } else {
            return (NSString *)nil;
        }
    } copy];
    
    OTMValidatorValidation curPassword = [^(OTMPasswordChangeViewController *vc) {
        OTMUser *user = [SharedAppDelegate loginManager].loggedInUser;
        
        if (![user.password isEqualToString:vc.oldPassword.text]) {
            return @"Your current password is incorrect, please try again";
        } else {
            return (NSString *)nil;
        }
    } copy];
    
    validator = [[OTMValidator alloc] initWithValidations:[NSArray arrayWithObjects:
                    [OTMTextFieldValidator notBlankValidation:@"oldPassword"
                                             display:@"Current password"],
                    [OTMTextFieldValidator minLengthValidation:@"aNewPassword"
                                              display:@"New password"
                                            minLength:6],
                     equalsValidation,
                     curPassword,
                     requiresLogin, nil]];
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

// called when text fields are completed
-(IBAction)completedForm:(id)sender {
    [self changePassword:sender];
}

-(IBAction)changePassword:(id)sender {
    if ([validator executeValidationsAndAlertWithViewController:self]) {
        OTMUser *user = [SharedAppDelegate loginManager].loggedInUser;
        
        [[[OTMEnvironment sharedEnvironment] api] changePasswordForUser:user 
                                                              to:self.aNewPassword.text 
                                                        callback:^(OTMUser *u, NSDictionary *instance, OTMAPILoginResponse r)
         {
             if (r == kOTMAPILoginResponseOK) {
                 [self.navigationController popViewControllerAnimated:YES];
             } else {
                 [[[UIAlertView alloc] initWithTitle:@"Server Error"
                                             message:@"Couldn't change password"
                                            delegate:nil
                                   cancelButtonTitle:@"OK"
                                   otherButtonTitles:nil] show];
             }
         }];
    }
}

@end
