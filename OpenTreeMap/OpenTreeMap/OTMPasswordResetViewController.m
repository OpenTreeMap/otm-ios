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

#import "OTMPasswordResetViewController.h"
#import "OTMAPI.h"
#import "OTMLoginManager.h"

@interface OTMPasswordResetViewController ()

@end

@implementation OTMPasswordResetViewController

@synthesize email;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(BOOL)validEmail {
    //This regex was copied from the django regex in validators.py
    NSString *emailregex = @"(^[-!#$%&'*+/=?^_`{}|~0-9A-Z]+(\\.[-!#$%&'*+/=?^_`{}|~0-9A-Z]+)*|^\"([\001-\010\013\014\016-\037!#-\\[\\]-\177]|\\[\001-\011\013\014\016-\177])*\")@((?:[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?\\.)+[A-Z]{2,6}\\.?$)|\\[(25[0-5]|2[0-4]\\d|[0-1]?\\d?\\d)(\\.(25[0-5]|2[0-4]\\d|[0-1]?\\d?\\d)){3}\\]$";
    
    NSError *error;
    NSRegularExpression *regep = [NSRegularExpression regularExpressionWithPattern:emailregex options:NSRegularExpressionCaseInsensitive error:&error];
    
    return [regep numberOfMatchesInString:self.email.text
                                  options:0
                                    range:NSMakeRange(0, [self.email.text length])] == 1;
}

-(void)showInvalidEmailAlert {
    [[[UIAlertView alloc] initWithTitle:@"Invalid Email"
                                message:@"We couldn't find your email in our database. Please try again."
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

-(IBAction)resetPassword:(id)sender {
    if (![self validEmail]) {
        [self showInvalidEmailAlert];
        return;
    }
    
    self.view.userInteractionEnabled = NO;
    [[[OTMEnvironment sharedEnvironment] api] resetPasswordForEmail:self.email.text
                                                           callback:^(NSDictionary *json, NSError *error) 
     {
         self.view.userInteractionEnabled = YES;
         if (error == nil && [[json objectForKey:@"status"] isEqualToString:@"success"]) {
             [[NSNotificationCenter defaultCenter] postNotificationName:kOTMLoginWorkflowPasswordReset
                                                                 object:self];
         } else {
             if (error == nil) { // Failure mode: invalid data
                 [self showInvalidEmailAlert];
             } else { // Failure mode: network
                 [[[UIAlertView alloc] initWithTitle:@"Communication Error"
                                             message:@"We couldn't communicate with the server. Please try again later."
                                            delegate:nil
                                   cancelButtonTitle:@"OK"
                                   otherButtonTitles:nil] show];                 
             }
         }
     }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
