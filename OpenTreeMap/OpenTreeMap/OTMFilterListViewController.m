//
//  OTMFilterListViewController.m
//  OpenTreeMap
//
//  Created by Adam Hinz on 5/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OTMFilterListViewController.h"
#import "OTMSpeciesTableViewController.h"

@implementation OTMFilters

@synthesize missingTree, missingDBH, missingSpecies, filters, speciesName, speciesId, listFilterType;

- (BOOL)active {
    return [self standardFiltersActive] || [self customFiltersActive];
}

- (BOOL)standardFiltersActive {
    return missingTree || missingDBH || missingSpecies;
}

- (BOOL)customFiltersActive {
    if (speciesId != nil) { return true; }

    for(OTMFilter *f in filters) {
        if ([f active]) {
            return true;
        }
    }

    return false;
}

- (NSDictionary *)filtersDict {
    NSMutableDictionary *m = [NSMutableDictionary dictionary];
    [m addEntriesFromDictionary:[self customFiltersDict]];

    if ([self listFilterType] == kOTMFiltersShowRecent) {
        [m setObject:@"true" forKey:@"filter_recent"];
    } else if ([self listFilterType] == kOTMFiltersShowPending) {
        [m setObject:@"true" forKey:@"filter_pending"];
    }

    return m;
}

- (NSDictionary *)customFiltersDict {
    NSMutableDictionary *m = [NSMutableDictionary dictionary];
    if (speciesId != nil) {
        [m setObject:speciesId forKey:@"filter_species"];
    }

    for(OTMFilter *f in filters) {
        [m addEntriesFromDictionary:[f queryParams]];
    }
    return m;
}

@end 

@interface OTMFilter () 
- (void)setName:(NSString *)s;
- (void)setKey:(NSString *)k;
- (void)setView:(UIView *)k;

- (BOOL)viewSet;
@end

@implementation OTMFilter

@synthesize view, name, key, delegate;

+ (OTMFilter *)filterFromDictionary:(NSDictionary *)dict {
    return [NSClassFromString([dict objectForKey:OTMFilterKeyType]) filterFromDictionary:dict];
}

- (NSString *)queryString { ABSTRACT_METHOD_BODY }
- (BOOL)active { ABSTRACT_METHOD_BODY }
- (void)clear { ABSTRACT_METHOD_BODY }
- (void)resignFirstResponder { /* Stub for concreate filters with text boxes */ }

- (void)setKey:(NSString *)k {
    key = k;
}

- (void)setName:(NSString *)s {
    name = s;
}

- (void)setView:(UIView *)v {
    view = v;
}

- (BOOL)viewSet { return view != nil; }

@end

@implementation OTMBoolFilter

@synthesize toggle, nameLbl;

+ (OTMFilter *)filterFromDictionary:(NSDictionary *)dict {
    return [[OTMBoolFilter alloc] initWithName:[dict objectForKey:OTMFilterKeyName] key:[dict objectForKey:OTMFilterKeyKey]];
}

- (id)initWithName:(NSString *)nm key:(NSString *)k {
    self = [super init];
    if (self) {
        [self setName:nm];
        [self setKey:k];
    }

    return self;
}

- (UIView *)view {
    if (![self viewSet]) {
        [self setView:[self createView]];
    }
    return [super view];
}

- (UIView *)createView {
    CGRect r = CGRectMake(0,0,320,40);
    [self setView:[[UIView alloc] initWithFrame:r]];

    nameLbl = [[UILabel alloc] initWithFrame:CGRectOffset(self.view.frame, 21, 0)];
    nameLbl.backgroundColor = [UIColor clearColor];
    nameLbl.textAlignment = UITextAlignmentLeft;
    nameLbl.text = self.name;
  
    CGRect switchRect = CGRectMake(0,0,79,27); // this isthe default (and only?) size for an iOS toggle switch
    CGFloat rightPad = 20.0;
    CGFloat ox = r.size.width - (rightPad + switchRect.size.width);
    CGFloat oy = (int)((r.size.height - switchRect.size.height) / 2.0);

    toggle = [[UISwitch alloc] initWithFrame:CGRectOffset(switchRect, ox, oy)];

    [self.view addSubview:nameLbl];
    [self.view addSubview:toggle];

    return self.view;
}

- (BOOL)active {
    return toggle.on;
}

- (void)clear {
    [toggle setOn:NO animated:YES];
}

- (NSString *)queryParams {
    if ([self active]) {
        return [NSDictionary dictionaryWithObjectsAndKeys:toggle.on ? @"true" : @"false", self.key, nil];
    } else {
        return [NSDictionary dictionary];
    }
}

@end

@implementation OTMRangeFilter

@synthesize nameLbl, maxValue, minValue;

+ (OTMFilter *)filterFromDictionary:(NSDictionary *)dict {
    return [[OTMRangeFilter alloc] initWithName:[dict objectForKey:OTMFilterKeyName] key:[dict objectForKey:OTMFilterKeyKey]];
}

- (id)initWithName:(NSString *)nm key:(NSString *)k {
    self = [super init];
    if (self) {
        [self setName:nm];
        [self setKey:k];
    }

    return self;
}

- (UIView *)view {
    if (![self viewSet]) {
        [self setView:[self createView]];
    }

    return [super view];
}

- (UIView *)createView {
    CGRect r = CGRectMake(0,0,320,75);
    [self setView:[[UIView alloc] initWithFrame:r]];

    CGFloat padding = 10.0f;

    CGRect nameFrame = CGRectMake(21,0,320,50);
    CGRect leftFrame = CGRectMake(106,10,79,31);
    CGRect toFrame = CGRectOffset(leftFrame, leftFrame.size.width + padding, 0);
    CGRect rightFrame = CGRectOffset(leftFrame, leftFrame.size.width + padding + 25, 0);

    nameLbl = [[UILabel alloc] initWithFrame:nameFrame];
    nameLbl.backgroundColor = [UIColor clearColor];
    nameLbl.text = self.name;
    minValue = [[UITextField alloc] initWithFrame:leftFrame];
    maxValue = [[UITextField alloc] initWithFrame:rightFrame];

    minValue.keyboardType = UIKeyboardTypeNumberPad;
    maxValue.keyboardType = UIKeyboardTypeNumberPad;

    [minValue setDelegate:[self delegate]];
    [maxValue setDelegate:[self delegate]];

    minValue.borderStyle = UITextBorderStyleRoundedRect;
    maxValue.borderStyle = UITextBorderStyleRoundedRect;

    UILabel *toLabel = [[UILabel alloc] initWithFrame:toFrame];
    toLabel.backgroundColor = [UIColor clearColor];
    toLabel.text = @"to";

    [self.view addSubview:nameLbl];
    [self.view addSubview:minValue];
    [self.view addSubview:maxValue];
    [self.view addSubview:toLabel];

    return self.view;
}

- (void)setDelegate:(id)d {
    [super setDelegate:d];
    [minValue setDelegate:d];
    [maxValue setDelegate:d];
}   

- (BOOL)active {
    //TODO- How to handle this?
    return ([minValue.text intValue] != 0 || [maxValue.text intValue] != 0);
}

- (void)clear {
    minValue.text = nil;
    maxValue.text = nil;
}

- (void)resignFirstResponder {
    [minValue resignFirstResponder];
    [maxValue resignFirstResponder];
}

- (NSString *)queryParams {
    if ([self active]) {
        NSString *max = [NSString stringWithFormat:@"%@_max",self.key];
        NSString *min = [NSString stringWithFormat:@"%@_min",self.key];
        return [NSDictionary dictionaryWithObjectsAndKeys:maxValue.text, max, minValue.text, min, nil];
    } else {
        return [NSDictionary dictionary];
    }
}

@end


@interface OTMFilterListViewController ()

@end

@implementation OTMFilterListViewController

@synthesize callback, missingTree, missingDBH, missingSpecies, scrollView, filters, otherFiltersView, speciesButton, speciesName, speciesId;

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

- (void)setAllFilters:(OTMFilters *)f 
{
    self.missingTree.on = f.missingTree;
    self.missingDBH.on = f.missingDBH;
    self.missingSpecies.on = f.missingSpecies;
    self.speciesName = f.speciesName;
    self.speciesId = f.speciesId;

    filters = f.filters;

    [self buildFilters:f.filters];
}

- (IBAction)updateFilters:(id)sender {
    if (callback) {
        callback([self generateFilters]);
    }
    for (OTMFilter *filter in filters) {
        [filter resignFirstResponder];
    }
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)clearFilters:(id)sender {
    [self.missingTree setOn:NO animated:YES];
    [self.missingDBH setOn:NO animated:YES];
    [self.missingSpecies setOn:NO animated:YES];
    [self setSpeciesName:nil];
    speciesId = nil;
    for (OTMFilter *filter in filters) {
        [filter clear];
    }
}

- (OTMFilters *)generateFilters {
    OTMFilters *filtersobj = [[OTMFilters alloc] init];
    filtersobj.missingTree = missingTree.on;
    filtersobj.missingDBH = missingDBH.on;
    filtersobj.missingSpecies = missingSpecies.on;
    filtersobj.speciesId = self.speciesId;
    filtersobj.speciesName = self.speciesName;

    filtersobj.filters = filters;

    return filtersobj;
}

/**
 * Should be a list of filter objects
 */
- (void)buildFilters:(NSArray *)f {
    CGFloat pad = 0.0f;

    // Reset filters frame
    for (UIView *v in otherFiltersView.subviews) { [v removeFromSuperview]; }

    otherFiltersView.frame = CGRectMake(otherFiltersView.frame.origin.x,
                                        otherFiltersView.frame.origin.y + 18,
                                        otherFiltersView.frame.size.width,
                                        0.0);
  
    for(OTMFilter *filter in filters) {
        filter.delegate = self;
        UIView *v = [filter view];
        v.frame = CGRectMake(v.frame.origin.x, otherFiltersView.frame.size.height, v.frame.size.width, v.frame.size.height);
        [otherFiltersView addSubview:v];

        otherFiltersView.frame = CGRectMake(otherFiltersView.frame.origin.x,
                                            otherFiltersView.frame.origin.y,
                                            otherFiltersView.frame.size.width,
                                            otherFiltersView.frame.size.height + v.frame.size.height + pad);
    }    

    scrollView.contentSize = CGSizeMake(otherFiltersView.frame.size.width,
                                        otherFiltersView.frame.origin.y + otherFiltersView.frame.size.height + pad);
  
}

- (void)setSpeciesName:(NSString *)name {
    speciesName = name;

    if (name == nil) {
        name = @"Not Filtered";
    }

    [speciesButton setTitle:[NSString stringWithFormat:@"Species: %@",name] forState: UIControlStateNormal];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender 
{
    if ([segue.identifier isEqualToString:@"pushSpecies"]) {
        OTMSpeciesTableViewController *vc = (OTMSpeciesTableViewController *)segue.destinationViewController;
        [vc view]; // Force the view to load

        vc.callback = ^(NSString *sid, NSString *species) {
            self.speciesName = species;
            self.speciesId = sid;
        };
    }
}


@end
