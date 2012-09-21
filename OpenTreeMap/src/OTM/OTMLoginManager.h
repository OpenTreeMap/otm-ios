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

#import <Foundation/Foundation.h>
#import "OTMUser.h"
#import "OTMLoginViewController.h"

#define kOTMLoginWorkflowCompletedSuccess @"kOTMLoginWorkflowCompletedSuccess"
#define kOTMLoginWorkflowCompletedFailure @"kOTMLoginWorkflowCompletedFailure"
#define kOTMLoginWorkflowUserRegistered @"kOTMLoginWorkflowUserRegistered"
#define kOTMLoginWorkflowPasswordReset @"kOTMLoginWorkflowPasswordReset"
#define kOTMLoginWorkflowLogout @"kOTMLoginWorkflowLogout"

typedef void(^OTMLoginCallback)(BOOL success, OTMUser* user);
typedef void(^OTMLoginUserCallback)(OTMUser *user);

/**
 * The OTMLoginManager acts a facade between the API login and the OTM
 * user. It also deals with the login UI flows and notifications.
 *
 * One of the following notifications are always fired:
 * kOTMLoginWorkflowCompletedSuccess      - Whenever the user successfully logs in
 * kOTMLoginWorkflowCompletedFailure      - If the user cancels the login process
 *
 * In addition, if the user registers as part of the login process:
 * kOTMLoginWorkflowUserRegistered        - After a successful registration
 *
 * This call is neither threadsafe nor reentrant
 */
@interface OTMLoginManager : NSObject<OTMLoginManagerDelegate> {
    UIStoryboard *loginWorkflow;
    OTMLoginViewController *loginVC;
    OTMLoginCallback callback;
    UINavigationController* rootVC;
}

@property (assign) BOOL runningLogin;
@property (strong) Function0v autoLoginFailed;
@property (nonatomic,strong) OTMUser *loggedInUser;

/**
 * Start the login workflow as a modal VC
 *
 * @param viewController The view controller to present in
 */
-(void)presentModelLoginInViewController:(UIViewController*)viewController;

/**
 * Start the login workflow as a modal VC and register a callback
 *
 * @param viewController The view controller to present in
 * @param callback Called when the login process has finished
 */
-(void)presentModelLoginInViewController:(UIViewController*)viewController callback:(OTMLoginCallback)callback;

/**
 * Called when the login controller is done with logging in
 */
-(void)loginController:(OTMLoginViewController*)vc loggedInWithUser:(OTMUser*)user;

/**
 * Install a callback handler if this is running the "auto login" sequence
 *
 * It is safe to always call this method
 */
-(void)installAutoLoginFailedCallback:(Function0v)f;


@end
