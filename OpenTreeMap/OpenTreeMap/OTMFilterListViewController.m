//
//  OTMFilterListViewController.m
//  OpenTreeMap
//
//  Created by Adam Hinz on 5/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OTMFilterListViewController.h"

@implementation OTMFilters

@synthesize missingTree, missingDBH, missingSpecies;

@end 

@interface OTMFilterListViewController ()

@end

@implementation OTMFilterListViewController
@synthesize callback, missingTree, missingDBH, missingSpecies;

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
	// Do any additional setup after loading the view.
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

- (void)setFilters:(OTMFilters *)f 
{
    self.missingTree.on = f.missingTree;
    self.missingDBH.on = f.missingDBH;
    self.missingSpecies.on = f.missingSpecies;
}

- (IBAction)updateFilters:(id)sender {
    if (callback) {
      callback([self generateFilters]);
    }

    [self dismissModalViewControllerAnimated:YES];
}

- (OTMFilters *)generateFilters {
    OTMFilters *filters = [[OTMFilters alloc] init];
    filters.missingTree = missingTree.on;
    filters.missingDBH = missingDBH.on;
    filters.missingSpecies = missingSpecies.on;

    return filters;
}

@end
