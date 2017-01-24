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

#import "OTMLoginManager.h"
#import "OTMAppDelegate.h"

@implementation OTMLoginManager

@synthesize loggedInUser, runningLogin, autoLoginFailed;

-(id)init {
    self = [super init];
    if (self) {
        loginWorkflow = [UIStoryboard storyboardWithName:@"LoginStoryboard"
                                                  bundle:nil];
        rootVC = [loginWorkflow instantiateInitialViewController];
        loginVC = [[rootVC viewControllers] objectAtIndex:0];
        loginVC.loginDelegate = self;

        OTMUser *user = [[OTMUser alloc] init];
        user.keychain = [SharedAppDelegate keychain];

        // Just assume that this is correct for now. Prevents app
        // loading race conditions
        self.loggedInUser = user;

        if (user.username && user.password && [user.username length] > 0 && [user.password length] > 0) {
            self.runningLogin = YES;
            [[[OTMEnvironment sharedEnvironment] api] logUserIn:user callback:^(OTMUser *u, NSDictionary *instance, OTMAPILoginResponse loginResp)
             {
                 if (loginResp == kOTMAPILoginResponseOK) {
                     self.loggedInUser = u;
                     self.runningLogin = NO;
                 } else {
                     self.loggedInUser = nil;
                     [self setRunningLoginDoneWithFailure];
                 }
             }];
        }

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(logout:)
                                                     name:kOTMLoginWorkflowLogout
                                                   object:nil];
    }

    return self;
}

-(void)logout:(NSNotification *)note {
    [self.loggedInUser logout];
    self.loggedInUser = nil;
}

// callback if autologin fails
-(void)setAutoLoginFailed:(Function0v)alf {
    @synchronized(self) {
        autoLoginFailed = [alf copy];
    }
}

// callback if autologin fails
-(Function0v)autoLoginFailed {
    @synchronized(self) {
        return autoLoginFailed;
    }
}

-(void)setRunningLogin:(BOOL)rl {
    @synchronized(self) {
        runningLogin = rl;
    }
}

// atomically set the callback if the
// auto login is running
-(void)installAutoLoginFailedCallback:(Function0v)f {
    @synchronized(self) {
        if (runningLogin) {
            autoLoginFailed = f;
        }
    }
}

// atomically clear the running flag and
// call and clear the update handler
-(void)setRunningLoginDoneWithFailure {
    @synchronized(self) {
        runningLogin = NO;
        if (autoLoginFailed) {
            autoLoginFailed();

            autoLoginFailed = nil;
        }
    }
}

-(BOOL)runningLogin {
    return runningLogin;
}

-(void)delayLoop:(NSArray *)objs {
    [self presentModelLoginInViewController:[objs objectAtIndex:0]
                                   callback:[objs objectAtIndex:1]];
}

-(void)presentModelLoginInViewController:(UIViewController*)viewController callback:(OTMLoginCallback)cb {

    if (runningLogin) {
        [self performSelector:@selector(delayLoop:)
                   withObject:[NSArray arrayWithObjects:viewController,cb, nil]
                   afterDelay:300.0];
        return;
    }

    if ([self.loggedInUser userId] > 0) {
        cb(YES, self.loggedInUser);
        return;

    }
    callback = [cb copy];

    [viewController presentViewController:rootVC animated:YES completion:nil];
}

-(void)presentModelLoginInViewController:(UIViewController*)viewController {
    [self presentModelLoginInViewController:viewController callback:nil];
}

-(void)loginController:(OTMLoginViewController*)vc loggedInWithUser:(OTMUser*)user {
    self.loggedInUser = user;

    [rootVC dismissViewControllerAnimated:YES completion:nil];

    [[NSNotificationCenter defaultCenter] postNotificationName:kOTMLoginWorkflowCompletedSuccess
                                                        object:user];

    if (callback != nil) {
        callback(true, user);
    }
}

-(void)loginControllerCanceledLogin:(OTMLoginViewController*)vc {
    [rootVC dismissViewControllerAnimated:YES completion:nil];

    [[NSNotificationCenter defaultCenter] postNotificationName:kOTMLoginWorkflowCompletedFailure
                                                        object:nil];

    if (callback != nil) {
        callback(false, nil);
    }
}

-(void)loginController:(OTMLoginViewController*)vc registeredUser:(OTMUser*)user {
    [[NSNotificationCenter defaultCenter] postNotificationName:kOTMLoginWorkflowUserRegistered
                                                        object:user];
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
