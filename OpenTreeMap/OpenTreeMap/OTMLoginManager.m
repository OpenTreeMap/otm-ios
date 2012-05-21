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
        user.keychain = [(OTMAppDelegate *)[[UIApplication sharedApplication] delegate] keychain];
        
        if (user.username && user.password && [user.username length] > 0 && [user.password length] > 0) {
            self.runningLogin = YES;
            [[[OTMEnvironment sharedEnvironment] api] logUserIn:user callback:^(OTMUser *u, OTMAPILoginResponse loginResp)
             {
                 if (loginResp == kOTMAPILoginResponseOK) {
                     self.loggedInUser = u;
                     self.runningLogin = NO;
                 } else {
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
    
    [viewController presentModalViewController:rootVC animated:YES];
}

-(void)presentModelLoginInViewController:(UIViewController*)viewController {
    [self presentModelLoginInViewController:viewController callback:nil];
}

-(void)loginController:(OTMLoginViewController*)vc loggedInWithUser:(OTMUser*)user {
    self.loggedInUser = user;
    
    [rootVC dismissModalViewControllerAnimated:YES];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kOTMLoginWorkflowCompletedSuccess
                                                        object:user];
    
    if (callback != nil) {
        callback(true, user);
    }
}

-(void)loginControllerCanceledLogin:(OTMLoginViewController*)vc {
    [rootVC dismissModalViewControllerAnimated:YES];
    
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
