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
    user.keychain = [SharedAppDelegate keychain];
    user.username = self.username.text;
    user.password = self.password.text;

    [[[OTMEnvironment sharedEnvironment] api] logUserIn:user callback:^(OTMUser* user, NSDictionary *instance, OTMAPILoginResponse resp) {
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

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewWillAppear:(BOOL)animated {
    username.text = @"";
    password.text = @"";
}


@end
