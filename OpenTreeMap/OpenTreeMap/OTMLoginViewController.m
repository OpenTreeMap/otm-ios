//
//  OTMLoginViewController.m
//  OpenTreeMap
//
//  Created by Adam Hinz on 3/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OTMLoginViewController.h"
#import "OTMUser.h"

@interface OTMLoginViewController ()

@end

@implementation OTMLoginViewController

@synthesize delegate, username, password;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (IBAction)attemptLogin:(id)sender {
    OTMUser* user = [[OTMUser alloc] init];

    [[[OTMEnvironment sharedEnvironment] api] logUserIn:user callback:^(id json, NSError* error) {
        NSLog(@"Got me some json back!");
    }];
}

- (IBAction)cancel:(id)sender {
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
