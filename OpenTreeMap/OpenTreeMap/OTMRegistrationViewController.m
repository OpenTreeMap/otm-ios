//
//  OTMRegistrationViewController.m
//  OpenTreeMap
//
//  Created by Adam Hinz on 3/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

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
            return nil;
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
        user.keychain = [(OTMAppDelegate*)[[UIApplication sharedApplication] delegate] keychain];
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
            } else {
                [[[UIAlertView alloc] initWithTitle:@"Server Error"
                                           message:@"There was a server error"
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
            // This gets around a weird bug where 
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
