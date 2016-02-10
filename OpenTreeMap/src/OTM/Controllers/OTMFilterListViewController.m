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

- (BOOL)active {
    if (_speciesId != nil) { return true; }

    for(OTMFilter *f in _filters) {
        if ([f active]) {
            return true;
        }
    }

    return false;
}

- (NSArray *)filtersDict {
    NSMutableArray *m = [[NSMutableArray alloc] init];
    [m addObjectsFromArray:[self customFiltersData]];

    if ([self listFilterType] == kOTMFiltersShowRecent) {
        [m addObject:@{ @"filter_recent" : @"true" }];
    } else if ([self listFilterType] == kOTMFiltersShowPending) {
        [m addObject:@{ @"filter_pending" : @"true" }];
    }

    return [m copy];
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

- (NSArray *)customFiltersData {
    NSMutableDictionary *andParams = [NSMutableDictionary dictionary];
    NSMutableDictionary *orParams = [NSMutableDictionary dictionary];

    if (_speciesId != nil) {
        andParams[@"species.id"] = @{ @"IS": _speciesId };
    }

    for(OTMFilter *f in _filters) {
        if (![f isKindOfClass:[OTMDefaultFilter class]]) {
            [andParams addEntriesFromDictionary:[f queryParams]];
        } else {
            [orParams addEntriesFromDictionary:[f queryParams]];
        }
    }

    NSMutableArray *orArray = [[NSMutableArray alloc] init];
    for (id key in orParams) {
        [orArray addObject:@{ key : [orParams objectForKey:key] }];
    }
    if ([orArray count]) {
        [orArray insertObject:@"OR" atIndex:0];
    }

    NSMutableArray *queryData = [[NSMutableArray alloc] init];
    if ([andParams count]) {
        [queryData addObject:@"AND"];
        for (id key in andParams) {
            [queryData addObject:@{key: [andParams objectForKey:key]}];
        }
        if ([orArray count]) {
            [queryData addObject:orArray];
        }
    } else {
        if ([orArray count]) {
            queryData = orArray;
        }
    }

    return queryData;
}

- (NSString *)description
{
    NSMutableArray *descriptions = [[NSMutableArray alloc] init];
    for(OTMFilter *f in _filters) {
        if ([f active]) {
            [descriptions addObject:[f name]];
        }
    }
    if (_speciesId != nil)
    {
        [descriptions addObject:_speciesName];
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
- (BOOL)needsLabel;
@end

@implementation OTMFilter

@synthesize view, name, key, delegate;

- (NSDictionary *)queryParams { ABSTRACT_METHOD_BODY }
- (NSString *)queryString { ABSTRACT_METHOD_BODY }
- (void)addSubviews { ABSTRACT_METHOD_BODY }
- (BOOL)active { ABSTRACT_METHOD_BODY }
- (void)clear { ABSTRACT_METHOD_BODY }
- (void)resignFirstResponder { /* Stub for concreate filters with text boxes */ }

- (void)setKey:(NSString *)k {
    key = k;
}

- (void)setName:(NSString *)s {
    name = s;
}

- (BOOL)needsLabel {
    return TRUE;
}

- (UIView *)view {
    if (view == nil) {
        [self createView];
    }
    return view;
}

- (void)createView {
    CGFloat viewWidth = 320;
    CGFloat xMargin = 20;
    CGFloat subviewWidth = viewWidth - 2 * xMargin;
    CGFloat labelBottomPadding = 2;
    CGFloat viewBottomPadding = 20;
    
    // Start with width we want subviews to stay within
    view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, subviewWidth, 0)];
    
    [self addSubviews];
    
    if ([self needsLabel]) {
        UILabel *label = [self makeLabel:subviewWidth];
        
        // Move each subview down to accomodate label height
        CGFloat dy = label.frame.size.height + labelBottomPadding;
        for (UIView *subview in view.subviews) {
            subview.frame = CGRectOffset(subview.frame, 0, dy);
        }
        [view addSubview:label];
    }
    
    // Move each subview left to accomodate x margin, and find lowest (y direction) subview.
    CGFloat yMax = 0;
    for (UIView *subview in view.subviews) {
        subview.frame = CGRectOffset(subview.frame, xMargin, 0);
        yMax = MAX(yMax, CGRectGetMaxY(subview.frame));
    }
    
    // Add a horizontal line
    CGFloat ySeparator = yMax + viewBottomPadding / 2.0 - 1;
    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(xMargin, ySeparator, subviewWidth, 0.5)];
    separator.backgroundColor = [UIColor colorWithWhite:0.75 alpha:1];
    [self.view addSubview:separator];
    
    // Expand frame to accomodate margins and padding
    view.frame = CGRectMake(0, 0, viewWidth, yMax + viewBottomPadding);
}

- (UILabel *)makeLabel:(CGFloat) width {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, width, 0)];
    label.backgroundColor = [UIColor clearColor];
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.numberOfLines = 0;
    label.text = self.name;
    [label sizeToFit];
    return label;
}

@end

@implementation OTMFilterSpacer

@synthesize space;

- (id)initWithSpace:(CGFloat)s {
    if ((self = [super init])) {
        space = s;
    }
    return self;
}

- (void)addSubviews {
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, space)];
    [self.view addSubview:v];
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

@implementation OTMToggleFilter

- (BOOL)needsLabel {
    return FALSE;
}

- (void)addSubviews {
    const CGFloat viewWidth = self.view.frame.size.width;
    const CGFloat gutter = 10; // padding between label and toggle
    
    // Compute right-aligned toggle position based on its size
    _toggle = [[UISwitch alloc] initWithFrame:CGRectZero];
    CGFloat toggleX = viewWidth - _toggle.frame.size.width;
    
    // Make a label using the remaining horizontal width
    CGFloat labelWidth = toggleX - gutter;
    UILabel *label = [self makeLabel:labelWidth];
    
    // Center toggle vertically
    CGFloat toggleY = (int)((label.frame.size.height - _toggle.frame.size.height) / 2.0);
    _toggle.frame = CGRectOffset(_toggle.frame, toggleX, toggleY);
    
    [self.view addSubview:label];
    [self.view addSubview:_toggle];
}

- (BOOL)active {
    return _toggle.on;
}

- (void)clear {
    [_toggle setOn:NO animated:YES];
}

@end

@implementation OTMBoolFilter

- (id)initWithName:(NSString *)nm key:(NSString *)k {
    return [self initWithName:nm key:k existanceFilter:NO];
}

- (id)initWithName:(NSString *)nm key:(NSString *)k existanceFilter:(BOOL)existanceFilter {
    self = [super init];
    if (self) {
        [self setName:nm];
        [self setKey:k];
        _existanceFilter = existanceFilter;
    }
    
    return self;
}

- (NSDictionary *)queryParams {
    if ([self active]) {
        if ([self existanceFilter]) {
            return @{ self.key: @{ @"ISNULL": @"true" }};
        } else {
            return [NSDictionary dictionaryWithObjectsAndKeys:self.toggle.on ? @"true" : @"false", self.key, nil];
        }
    } else {
        return [NSDictionary dictionary];
    }
}

@end

/**
 * Filter class to handle choices that have a default value. This was
 * specifically built to handle filters for alerts. Mostly a direct copy of the
 * boolean search but with the data set to a default value provided by the
 * fields data.
 */
@implementation OTMDefaultFilter

- (id)initWithName:(NSString *)nm
               key:(NSString *)k
        defaultKey:(NSString *)dk
      defaultValue:(NSString *)dv
{
    self = [super init];
    if (self) {
        [self setName:nm];
        [self setKey:k];
        [self setDefaultKey:dk];
        [self setDefaultValue:dv];
    }

    return self;
}

- (void)setDefaultKey:(NSString *)defaultKey
{
    _defaultKey = defaultKey;
}

- (void)setDefaultValue:(NSString *)defaultValue
{
    _defaultValue = defaultValue;
}

- (NSDictionary *)queryParams {
    if ([self active]) {
        return @{ self.key : self.defaultValue };
    } else {
        return [NSDictionary dictionary];
    }
}

@end

@implementation OTMChoiceFilter

@synthesize button, tvc, selectedChoice, allChoices, isMulti;

- (id)initWithName:(NSString *)nm key:(NSString *)k choices:(NSArray *)choices isMulti:(BOOL)multi {
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

        isMulti = multi;
        allChoices = choices;
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

- (BOOL)needsLabel {
    return FALSE;
}

- (void)addSubviews {
    // Make a throwaway label so we can use its font and height
    UILabel *label = [self makeLabel:self.view.frame.size.width];
    button.titleLabel.font = label.font;
    button.frame = CGRectMake(0, 0,  self.view.frame.size.width, label.frame.size.height);

    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self updateButtonText];

    [self.view addSubview:button];
}

- (BOOL)active {
    return selectedChoice != nil;
}

- (NSString *)selectedValue { return [selectedChoice objectForKey:@"value"]; }
- (NSString *)selectedKey { return [selectedChoice objectForKey:@"key"]; }

- (void)updateButtonText {
    NSString *value = [self selectedValue];
    NSString *title = value == nil ? self.name : [NSString stringWithFormat:@"%@: %@",self.name,value];
    [button setTitle:title forState:UIControlStateNormal];
}

- (void)clear {
    selectedChoice = nil;
    [self updateButtonText];
    [tvc.tableView reloadData];
}

- (NSDictionary *)queryParams {
    if ([self active]) {
        if (isMulti) {
            NSString *selectedValueQuoted = [NSString stringWithFormat:@"\"%@\"",[self selectedValue]];
            return @{self.key: @{ @"LIKE": selectedValueQuoted}};
        } else {
            return @{self.key: @{ @"IS": [self selectedValue]}};
        }
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

@synthesize maxValue, minValue;

- (id)initWithName:(NSString *)nm key:(NSString *)k {
    self = [super init];
    if (self) {
        [self setName:nm];
        [self setKey:k];
    }

    return self;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {

    NSString *newText = [textField.text stringByReplacingCharactersInRange:range
                                                                withString:string];

    return [[newText componentsSeparatedByString:@"."] count] <= 2;
}

- (void)addSubviews {
    CGFloat padding = 10;

    CGRect leftFrame = CGRectMake(0,0,65,31);
    CGRect toFrame = CGRectOffset(leftFrame, leftFrame.size.width + padding, 0);
    CGRect rightFrame = CGRectOffset(leftFrame, leftFrame.size.width + padding + 25, 0);

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

    [self.view addSubview:minValue];
    [self.view addSubview:maxValue];
    [self.view addSubview:toLabel];
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
    self.speciesName = f.speciesName;
    self.speciesId = f.speciesId;

    _filters = f.filters;

    [self buildFilters:f.filters];
}

- (IBAction)updateFilters:(id)sender {
    if (_callback) {
        _callback([self generateFilters]);
    }
    for (OTMFilter *filter in _filters) {
        [filter resignFirstResponder];
    }
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)clearFilters:(id)sender {
    [self setSpeciesName:nil];
    _speciesId = nil;
    for (OTMFilter *filter in _filters) {
        [filter clear];
    }
}

- (OTMFilters *)generateFilters {
    OTMFilters *filtersobj = [[OTMFilters alloc] init];
    filtersobj.speciesId = self.speciesId;
    filtersobj.speciesName = self.speciesName;

    filtersobj.filters = _filters;

    return filtersobj;
}

/**
 * Should be a list of filter objects
 */
- (void)buildFilters:(NSArray *)f {
    CGFloat pad = 0.0f;

    // Reset filters frame
    for (UIView *v in _otherFiltersView.subviews) { [v removeFromSuperview]; }

    _otherFiltersView.frame = CGRectMake(_otherFiltersView.frame.origin.x,
                                        _otherFiltersView.frame.origin.y + 18,
                                        _otherFiltersView.frame.size.width,
                                        0.0);

    for(OTMFilter *filter in _filters) {
        filter.delegate = self;
        UIView *v = [filter view];
        v.frame = CGRectMake(v.frame.origin.x, _otherFiltersView.frame.size.height, v.frame.size.width, v.frame.size.height);
        [_otherFiltersView addSubview:v];

        _otherFiltersView.frame = CGRectMake(_otherFiltersView.frame.origin.x,
                                            _otherFiltersView.frame.origin.y,
                                            _otherFiltersView.frame.size.width,
                                            _otherFiltersView.frame.size.height + v.frame.size.height + pad);
    }

    self.scrollView.contentSize = CGSizeMake(_otherFiltersView.frame.size.width,
                                        _otherFiltersView.frame.origin.y + _otherFiltersView.frame.size.height + pad);

}

- (void)setSpeciesName:(NSString *)name {
    _speciesName = name;

    if (name == nil) {
        name = @"Not Filtered";
    }

    [_speciesButton setTitle:[NSString stringWithFormat:@"Species: %@",name] forState: UIControlStateNormal];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"pushSpecies"]) {
        OTMSpeciesTableViewController *vc = (OTMSpeciesTableViewController *)segue.destinationViewController;
        [vc view]; // Force the view to load

        vc.callback = ^(NSDictionary *sdict) {
            self.speciesName = sdict[@"common_name"];
            self.speciesId = sdict[@"id"];
        };
    }
}


@end
