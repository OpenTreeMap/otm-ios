//
//  OTMFilterListViewController.m
//  OpenTreeMap
//
//  Created by Adam Hinz on 5/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OTMFilterListViewController.h"

@implementation OTMFilters

@synthesize missingTree, missingDBH, missingSpecies, queryStrings;

@end 

@interface OTMFilter () 
- (void)setName:(NSString *)s;
- (void)setKey:(NSString *)k;
- (void)setView:(UIView *)k;
@end

@implementation OTMFilter

@synthesize view, name, key;

- (NSString *)queryString { ABSTRACT_METHOD_BODY }

- (void)setKey:(NSString *)k {
  key = k;
}

- (void)setName:(NSString *)s {
  name = s;
}

- (void)setView:(UIView *)v {
  view = v;
}

@end

@implementation OTMBoolFilter

@synthesize toggle, nameLbl;

- (id)initWithName:(NSString *)nm key:(NSString *)k {
  self = [super init];
  if (self) {
    [self setName:nm];
    [self setKey:k];
  }

  return self;
}

- (UIView *)view {
  if ([self view] == nil) {
    [self setView:[self createView]];
  }
  return [self view];
}

- (UIView *)createView {
  CGRect r = CGRectMake(0,0,320,50);
  [self setView:[[UIView alloc] initWithFrame:r]];

  nameLbl = [[UILabel alloc] initWithFrame:self.view.frame]; // we'll just align left
  nameLbl.textAlignment = UITextAlignmentLeft;
  nameLbl.text = self.name;
  
  CGRect switchRect = CGRectMake(0,0,79,27); // these are standard values
  CGFloat rightPad = 20.0;
  CGFloat ox = r.size.width - (rightPad + switchRect.size.width);
  CGFloat oy = (r.size.height - switchRect.size.height) / 2.0;

  toggle = [[UISwitch alloc] initWithFrame:CGRectOffset(switchRect, ox, oy)];

  [self.view addSubview:nameLbl];
  [self.view addSubview:toggle];

  return self.view;
}

- (NSString *)queryString {
  return [NSString stringWithFormat:@"%@=%@", self.key, toggle.on ? @"true" : @"false"];
}

@end

@interface OTMFilterListViewController ()

@end

@implementation OTMFilterListViewController

@synthesize callback, missingTree, missingDBH, missingSpecies, scrollView, filters, otherFiltersView;

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
    OTMFilters *filtersobj = [[OTMFilters alloc] init];
    filtersobj.missingTree = missingTree.on;
    filtersobj.missingDBH = missingDBH.on;
    filtersobj.missingSpecies = missingSpecies.on;

    NSMutableArray *qstrings = [NSMutableArray array];

    for(OTMFilter *filter in filters) {
        [qstrings addObject:filter];
    }
   
    filtersobj.queryStrings = qstrings;

    return filtersobj;
}

/**
 * Should be a list of filter objects
 */
- (void)buildFilters:(NSArray *)f {
  filters = f;

  CGFloat pad = 10.0;

  // Reset filters frame
  for (UIView *v in otherFiltersView.subviews) { [v removeFromSuperview]; }
  otherFiltersView.frame = CGRectMake(otherFiltersView.frame.origin.x,
                                      otherFiltersView.frame.origin.y,
                                      otherFiltersView.frame.size.width,
                                      0.0);
  
  for(OTMFilter *filter in filters) {
    UIView *v = [filter view];
    v.frame = CGRectOffset(v.frame, 0, otherFiltersView.frame.origin.y);
    [otherFiltersView addSubview:v];

    otherFiltersView.frame = CGRectMake(otherFiltersView.frame.origin.x,
                                        otherFiltersView.frame.origin.y,
                                        otherFiltersView.frame.size.width,
                                        otherFiltersView.frame.size.height + v.frame.size.height + pad);
  }    

  scrollView.contentSize = CGSizeMake(otherFiltersView.frame.size.width,
                                      otherFiltersView.frame.origin.y + otherFiltersView.frame.size.height + pad);
  
}

@end
