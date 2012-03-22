//
//  OTMPasswordResetViewController.m
//  OpenTreeMap
//
//  Created by Adam Hinz on 3/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
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
    return [self.email.text rangeOfString:@"^.+@.+\\..{2,}$" options:NSRegularExpressionSearch].location != NSNotFound;
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
