//
//  OTMSplashViewController.m
//  OpenTreeMap
//
//  Created by Adam Hinz on 9/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OTMSplashViewController.h"

@interface OTMSplashViewController ()

@end

@implementation OTMSplashViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    float seconds = [[OTMEnvironment sharedEnvironment] splashDelayInSeconds];
    dispatch_time_t tgt = dispatch_time(DISPATCH_TIME_NOW, seconds * NSEC_PER_SEC);
    dispatch_after(tgt, dispatch_get_main_queue(), ^{
        [self performSegueWithIdentifier:@"startApp" sender:self];
    });
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
