//                                                                                                                
// Copyright (c) 2012 Azavea                                                                                
//                                                                                                                
// Permission is hereby granted, free of charge, to any person obtaining a copy                                   
// of this software and associated documentation files (the "Software"), to                                       
// deal in the Software without restriction, including without limitation the                                     
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or                                    
//  sell copies of the Software, and to permit persons to whom the Software is                                    
// furnished to do so, subject to the following conditions:                                                       
//                                                                                                                
// The above copyright notice and this permission notice shall be included in                                     
// all copies or substantial portions of the Software.                                                            
//                                                                                                                
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR                                     
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,                                       
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE                                    
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER                                         
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,                                  
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN                                      
// THE SOFTWARE.                                                                                                  
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
#pragma mark Actions

// Called after a successful password reset
// note that a password reset is considered a login failure
- (void)didFinishPasswordReset:(NSNotification*)note {
    [self.loginDelegate loginControllerCanceledLogin:self];
}

-(void)didRegisterUser:(NSNotification*)note {
    OTMUser *user = note.object;

    [self.loginDelegate loginController:self
                       loggedInWithUser:user];    
}

//overrides scroll completed
-(void)completedForm:(id)sender {
    [self attemptLogin:sender];
}

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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didFinishPasswordReset:) name:kOTMLoginWorkflowPasswordReset
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didRegisterUser:)
                                                 name:kOTMLoginWorkflowUserRegistered
                                               object:nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kOTMLoginWorkflowPasswordReset object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kOTMLoginWorkflowUserRegistered
                                                  object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
