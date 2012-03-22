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

#import <Foundation/Foundation.h>
#import "OTMUser.h"
#import "OTMLoginViewController.h"

#define kOTMLoginWorkflowCompletedSuccess @"kOTMLoginWorkflowCompletedSuccess"
#define kOTMLoginWorkflowCompletedFailure @"kOTMLoginWorkflowCompletedFailure"
#define kOTMLoginWorkflowUserRegistered @"kOTMLoginWorkflowUserRegistered"
#define kOTMLoginWorkflowPasswordReset @"kOTMLoginWorkflowPasswordReset"

typedef void(^OTMLoginCallback)(BOOL success, OTMUser* user);

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
 * Called when the login controller is regsistered a user
 */
-(void)loginController:(OTMLoginViewController*)vc registeredUser:(OTMUser*)user;

@end
