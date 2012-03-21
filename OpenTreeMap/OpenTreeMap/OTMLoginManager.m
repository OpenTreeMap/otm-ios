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

@implementation OTMLoginManager

-(id)init {
    self = [super init];
    if (self) {
        loginWorkflow = [UIStoryboard storyboardWithName:@"LoginStoryboard"
                                                  bundle:nil];
        rootVC = [loginWorkflow instantiateInitialViewController];
        loginVC = [[rootVC viewControllers] objectAtIndex:0];
        loginVC.loginDelegate = self;
    }
    
    return self;
}

-(void)presentModelLoginInViewController:(UIViewController*)viewController callback:(OTMLoginCallback)cb {
    callback = [cb copy];
    
    [viewController presentModalViewController:rootVC animated:YES];
}

-(void)presentModelLoginInViewController:(UIViewController*)viewController {
    [self presentModelLoginInViewController:viewController callback:nil];
}

-(void)loginController:(OTMLoginViewController*)vc loggedInWithUser:(OTMUser*)user {
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

@end
