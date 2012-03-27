//
//  OTMPasswordChangeViewController.m
//  OpenTreeMap
//
//  Created by Adam Hinz on 3/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OTMPasswordChangeViewController.h"

@interface OTMPasswordChangeViewController ()

@end

@implementation OTMPasswordChangeViewController

@synthesize validator, oldPassword, aNewPassword, aNewPasswordVerify;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    OTMValidatorValidation equalsValidation = [^(OTMPasswordChangeViewController *vc) {
        if (![vc.aNewPassword.text isEqualToString:vc.aNewPasswordVerify.text]) {
            return @"Password and password confirmation must match";
        } else {
            return nil;
        }
    } copy];
    
    // Note that we should never actually get to this validation
    // nor would we be able to change it, but just in case this provides a user
    // friendly message
    OTMValidatorValidation requiresLogin = [^(OTMPasswordChangeViewController *vc) {
        OTMUser *user = [(OTMAppDelegate *)[[UIApplication sharedApplication] delegate] loginManager].loggedInUser;
        
        if (user == nil) {
            return @"You must be logged in to change your password";
        } else {
            return nil;
        }
    } copy];
    
    OTMValidatorValidation curPassword = [^(OTMPasswordChangeViewController *vc) {
        OTMUser *user = [(OTMAppDelegate *)[[UIApplication sharedApplication] delegate] loginManager].loggedInUser;
        
        if (![user.password isEqualToString:vc.oldPassword.text]) {
            return @"Your current password is incorrect, please try again";
        } else {
            return nil;
        }
    } copy];
    
    validator = [[OTMValidator alloc] initWithValidations:[NSArray arrayWithObjects:
                    [OTMTextFieldValidator notBlankValidation:@"oldPassword"
                                             display:@"Current password"],
                    [OTMTextFieldValidator minLengthValidation:@"newPassword"
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

-(IBAction)changePassword:(id)sender {
    if ([validator executeValidationsAndAlertWithViewController:self]) {
        OTMUser *user = [(OTMAppDelegate *)[[UIApplication sharedApplication] delegate] loginManager].loggedInUser;
        
        [[[OTMEnvironment sharedEnvironment] api] changePassword:user 
                                                              to:self.aNewPassword.text 
                                                        callback:^(OTMUser *u, OTMAPILoginResponse r)
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
