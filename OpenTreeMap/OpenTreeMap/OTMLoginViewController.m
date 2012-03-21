//
//  OTMLoginViewController.m
//  OpenTreeMap
//
//  Created by Adam Hinz on 3/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OTMLoginViewController.h"
#import "OTMUser.h"
#import "OTMAPI.h"
#import "OTMEnvironment.h"
#import "OTMAppDelegate.h"

@interface OTMLoginViewController ()

@end

@implementation OTMLoginViewController

@synthesize loginDelegate, username, password, scrollView, activeField;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark -
#pragma mark Keyboard

-(IBAction)hideKeyboard:(id)sender {
    [activeField resignFirstResponder];
}

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    scrollView.contentInset = contentInsets;
    scrollView.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your application might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    if (!CGRectContainsPoint(aRect, activeField.frame.origin) ) {
        CGPoint scrollPoint = CGPointMake(0.0, activeField.frame.origin.y-kbSize.height);
        [scrollView setContentOffset:scrollPoint animated:YES];
    }
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    scrollView.contentInset = contentInsets;
    scrollView.scrollIndicatorInsets = contentInsets;
}

#pragma mark -
#pragma mark UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    activeField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    activeField = nil;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.username) {
        [self.password becomeFirstResponder];
    } else {
        [self attemptLogin:self.password];
    }
    return NO; // Don't stick newlines in the cell
}

#pragma mark -
#pragma mark Actions

- (IBAction)attemptLogin:(id)sender {
    // Disable changing things while we roll...
    self.view.userInteractionEnabled = NO;
    
    OTMUser* user = [[OTMUser alloc] init];
    user.keychain = [(OTMAppDelegate*)[[UIApplication sharedApplication] delegate] keychain];
    user.username = self.username.text;
    user.password = self.password.text;

    [[[OTMEnvironment sharedEnvironment] api] logUserIn:user callback:^(OTMUser* user, OTMAPILoginResponse resp) {
        self.view.userInteractionEnabled = YES;
        if (resp == kOTMAPILoginResponseInvalidUsernameOrPassword) {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Login Error"
                                                            message:@"Incorrect username or password"
                                                           delegate:nil
                                                  cancelButtonTitle:@"Try Again"
                                                  otherButtonTitles:nil];
            
            [alert show];
        } else if (resp == kOTMAPILoginResponseOK && user.loggedIn) {
            [self.loginDelegate loginController:self
                          loggedInWithUser:user];
        } else {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Login Error"
                                                            message:@"Could not connect to server"
                                                           delegate:nil
                                                  cancelButtonTitle:@"Try Again"
                                                  otherButtonTitles:nil];
            
            [alert show];
        }
    }];
}

- (IBAction)cancel:(id)sender {
    [self.loginDelegate loginControllerCanceledLogin:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.scrollView.contentSize = CGSizeMake(320,340);
    
    [self registerForKeyboardNotifications];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
