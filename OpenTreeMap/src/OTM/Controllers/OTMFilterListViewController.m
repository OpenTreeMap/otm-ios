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

    if (missingTree) {
        m[@"tree.id"] = @{ @"IS": [NSNull null] };
    }

    if (missingDBH) {
        m[@"tree.diameter"] = @{ @"IS": [NSNull null] };
    }
- (NSString *)filtersAsUrlParameter {
    NSDictionary *filtersDict = [self filtersDict];
    NSString *filter = nil;

    if ([filtersDict count] > 0) {
        filter = [[NSString alloc] initWithData:[OTMAPI jsonEncode:filtersDict]
                                       encoding:NSUTF8StringEncoding];
    }

    return filter;
}

- (NSDictionary *)customFiltersDict {
    NSMutableDictionary *m = [NSMutableDictionary dictionary];
    if (speciesId != nil) {
        m[@"species.id"] = @{ @"IS": speciesId };
    }

    for(OTMFilter *f in filters) {
        [m addEntriesFromDictionary:[f queryParams]];
    }
    return m;
}

- (NSString *)description
{
    NSMutableArray *descriptions = [[NSMutableArray alloc] init];
    if (missingTree) {
        [descriptions addObject:@"Missing Tree"];
    }
    if (missingSpecies) {
        [descriptions addObject:@"Missing Species"];
    }
    if (missingDBH) {
        [descriptions addObject:@"Missing Diameter"];
    }
    for(OTMFilter *f in filters) {
        if ([f active]) {
            [descriptions addObject:[f name]];
        }
    }
    if (speciesId != nil)
    {
        [descriptions addObject:speciesName];
    }
    if ([descriptions count] > 1) {
        return [descriptions componentsJoinedByString:@", "];
    } else {
        return [descriptions objectAtIndex:0];
    }
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

- (NSDictionary *)queryParams { ABSTRACT_METHOD_BODY }
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

@implementation OTMFilterSpacer

@synthesize space;

+ (OTMFilter *)filterFromDictionary:(NSDictionary *)dict {
    return [[OTMFilterSpacer alloc] initWithSpace:
                               [[dict valueForKey:@"OTMFilterSpaceHeight"] floatValue]];
}

- (id)initWithSpace:(CGFloat)s {
    if ((self = [super init])) {
        space = s;
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
    CGRect r = CGRectMake(0,0,320,space);
    [self setView:[[UIView alloc] initWithFrame:r]];

    return self.view;
}

- (BOOL)active {
    return NO;
}

- (void)clear {
}

- (NSDictionary *)queryParams {
    // This is an 'fake' filter, so nothing to
    // return here
    return [NSDictionary dictionary];
}


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

- (NSDictionary *)queryParams {
    if ([self active]) {
        return [NSDictionary dictionaryWithObjectsAndKeys:toggle.on ? @"true" : @"false", self.key, nil];
    } else {
        return [NSDictionary dictionary];
    }
}

@end

@implementation OTMChoiceFilter

@synthesize button, tvc, selectedChoice, allChoices;

+ (OTMFilter *)filterFromDictionary:(NSDictionary *)dict {
    return [[OTMChoiceFilter alloc] initWithName:[dict objectForKey:OTMFilterKeyName]
                                             key:[dict objectForKey:OTMFilterKeyKey]
                                       choiceKey:[dict objectForKey:OTMChoiceFilterChoiceKey]];
}

- (id)initWithName:(NSString *)nm key:(NSString *)k choiceKey:(NSString *)choiceKey {
    self = [super init];
    if (self) {
        [self setName:nm];
        [self setKey:k];

        tvc = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
        tvc.tableView.delegate = (id<UITableViewDelegate>)self;
        tvc.tableView.dataSource = (id<UITableViewDataSource>)self;

        tvc.navigationItem.rightBarButtonItem =
            [[UIBarButtonItem alloc] initWithTitle:@"Clear"
                                             style:UITableViewStylePlain
                                            target:self
                                            action:@selector(clear)];

        allChoices = [[[OTMEnvironment sharedEnvironment] choices] objectForKey:choiceKey];
        selectedChoice = nil;

        button = [[OTMButton alloc] init];
        [button addTarget:self
                   action:@selector(pushTableViewController)
         forControlEvents:UIControlEventTouchUpInside];
    }

    return self;
}

- (void)pushTableViewController {
    UINavigationController * nav = (UINavigationController *)[self.delegate parentViewController];
    [nav pushViewController:tvc animated:YES];
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

    button.frame = CGRectInset(r, 20, 2);
    [self updateButtonText];
    [self.view addSubview:button];

    return self.view;
}

- (BOOL)active {
    return selectedChoice != nil;
}

- (NSString *)selectedValue { return [selectedChoice objectForKey:@"value"]; }
- (NSString *)selectedKey { return [selectedChoice objectForKey:@"key"]; }

- (void)updateButtonText {
    if ([self active]) {
        [button setTitle:[NSString stringWithFormat:@"Pests: %@",[self selectedValue]]
                forState:UIControlStateNormal];
    } else {
        [button setTitle:@"Pests"
                forState:UIControlStateNormal];
    }
}

- (void)clear {
    selectedChoice = nil;
    [self updateButtonText];
    [tvc.tableView reloadData];
}

- (NSDictionary *)queryParams {
    if ([self active]) {
        return [NSDictionary dictionaryWithObjectsAndKeys:[self selectedKey],
                             self.key, nil];
    } else {
        return [NSDictionary dictionary];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [allChoices count];
}

- (void)tableView:(UITableView *)tblView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    selectedChoice = [allChoices objectAtIndex:[indexPath row]];

    [self updateButtonText];
    [tblView reloadData];
}

#define kOTMEditChoicesDetailCellRendererCellId @"kOTMEditChoicesDetailCellRendererCellId"

- (UITableViewCell *)tableView:(UITableView *)tblView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *selectedDict = [allChoices objectAtIndex:[indexPath row]];

    UITableViewCell *aCell = [tblView dequeueReusableCellWithIdentifier:kOTMEditChoicesDetailCellRendererCellId];

    if (aCell == nil) {
        aCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:kOTMEditChoicesDetailCellRendererCellId];
    }

    aCell.textLabel.text = [selectedDict objectForKey:@"value"];
    aCell.accessoryType = UITableViewCellAccessoryNone;

    if ([[selectedDict objectForKey:@"value"] isEqualToString:[self selectedValue]]) {
        aCell.accessoryType = UITableViewCellAccessoryCheckmark;
    }

    return aCell;
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

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {

    NSString *newText = [textField.text stringByReplacingCharactersInRange:range
                                                                withString:string];

    return [[newText componentsSeparatedByString:@"."] count] <= 2;
}

- (UIView *)createView {
    CGRect r = CGRectMake(0,0,320,55);
    [self setView:[[UIView alloc] initWithFrame:r]];

    CGFloat padding = 10.0f;

    CGRect nameFrame = CGRectMake(21,0,320,50);
    CGRect leftFrame = CGRectMake(135,10,65,31);
    CGRect toFrame = CGRectOffset(leftFrame, leftFrame.size.width + padding, 0);
    CGRect rightFrame = CGRectOffset(leftFrame, leftFrame.size.width + padding + 25, 0);

    nameLbl = [[UILabel alloc] initWithFrame:nameFrame];
    nameLbl.backgroundColor = [UIColor clearColor];
    nameLbl.text = self.name;
    minValue = [[UITextField alloc] initWithFrame:leftFrame];
    maxValue = [[UITextField alloc] initWithFrame:rightFrame];

    minValue.keyboardType = UIKeyboardTypeDecimalPad;
    maxValue.keyboardType = UIKeyboardTypeDecimalPad;

    [minValue setDelegate:self];
    [maxValue setDelegate:self];

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
}

- (BOOL)active {
    return ([minValue.text floatValue] != 0 || [maxValue.text floatValue] != 0);
}

- (void)clear {
    minValue.text = nil;
    maxValue.text = nil;
}

- (void)resignFirstResponder {
    [minValue resignFirstResponder];
    [maxValue resignFirstResponder];
}

- (NSDictionary *)queryParams {
    if ([self active]) {
        return @{self.key: @{ @"MIN": minValue.text, @"MAX": maxValue.text}};
    } else {
        return [NSDictionary dictionary];
    }
}

@end


@interface OTMFilterListViewController ()

@end

@implementation OTMFilterListViewController

@synthesize callback, missingTree, missingDBH, missingSpecies, scrollView, filters, otherFiltersView, speciesButton, speciesName, speciesId, missingTreeLabel;

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
    if ([[OTMEnvironment sharedEnvironment] hideTreesFilter]) {
        missingTreeLabel.hidden = YES;
        missingTree.hidden = YES;
    }
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

        vc.callback = ^(NSDictionary *sdict) {
            self.speciesName = sdict[@"species"];
            self.speciesId = sdict[@"id"];
        };
    }
}


@end
