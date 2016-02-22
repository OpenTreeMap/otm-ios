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
#import "AZPastelessTextField.h"
#import "AZInputViewAccessoryBarButtonItem.h"

@implementation OTMFilters

- (BOOL)active {
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

    for(OTMFilter *f in _filters) {
        if ([f isKindOfClass:[OTMDefaultFilter class]]) {
            [orParams addEntriesFromDictionary:[f queryParams]];
        } else {
            [andParams addEntriesFromDictionary:[f queryParams]];
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


@implementation OTMAbstractChoiceFilter

@synthesize button, tableViewController;

- (id)init:(UITableViewController *)tvc {
    self = [super init];
    tableViewController = tvc;
    button = [[OTMButton alloc] init];
    [button addTarget:self
               action:@selector(pushTableViewController)
     forControlEvents:UIControlEventTouchUpInside];
    return self;
}

- (void)pushTableViewController {
    UINavigationController * nav = (UINavigationController *)[self.delegate parentViewController];
    [nav pushViewController:tableViewController animated:YES];
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
    [self updateButtonText:nil];

    [self.view addSubview:button];
}

- (void)clear {
    [self updateButtonText:nil];
}

- (void)updateButtonText:(NSString *)text {
    NSString *title = text == nil ? self.name : [NSString stringWithFormat:@"%@: %@",self.name,text];
    [button setTitle:title forState:UIControlStateNormal];
}

@end


@implementation OTMSpeciesFilter

@synthesize speciesName, speciesId;

- (id)init {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
    OTMSpeciesTableViewController *stvc = [storyboard instantiateViewControllerWithIdentifier:@"SpeciesChooser"];
    self = [super init:stvc];

    [self setName:@"Species"];
    speciesName = nil;
    speciesId = nil;
    
    stvc.callback = ^(NSDictionary *sdict) {
        speciesName = sdict[@"common_name"];
        speciesId = sdict[@"id"];
        [self updateButtonText:[self speciesName]];
    };
    return self;
}

- (BOOL)active {
    return speciesId != nil;
}

- (void)clear {
    [super clear];
    speciesName = nil;
    speciesId = nil;
}

- (NSDictionary *)queryParams {
    if ([self active]) {
        return @{ @"species.id": @{ @"IS": speciesId }};
    } else {
        return [NSDictionary dictionary];
    }
}

@end


@implementation OTMChoiceFilter

@synthesize selectedChoice, allChoices, isMulti;

- (id)initWithName:(NSString *)nm key:(NSString *)k choices:(NSArray *)choices isMulti:(BOOL)multi {
    UITableViewController *tableViewController = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
    self = [super init:tableViewController];

    [self setName:nm];
    [self setKey:k];
    isMulti = multi;
    allChoices = choices;
    selectedChoice = nil;

    tableViewController.tableView.delegate = (id<UITableViewDelegate>)self;
    tableViewController.tableView.dataSource = (id<UITableViewDataSource>)self;
    tableViewController.navigationItem.rightBarButtonItem =
    [[UIBarButtonItem alloc] initWithTitle:@"Clear"
                                     style:UITableViewStylePlain
                                    target:self
                                    action:@selector(clear)];
    return self;
}

- (BOOL)active {
    return selectedChoice != nil;
}

- (NSString *)selectedValue { return [selectedChoice objectForKey:@"value"]; }
- (NSString *)selectedKey { return [selectedChoice objectForKey:@"key"]; }

- (void)clear {
    [super clear];
    selectedChoice = nil;
    [self.tableViewController.tableView reloadData];
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

    [self updateButtonText:[self selectedValue]];
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

    CGRect leftFrame = CGRectMake(0,0,122,31);
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

@implementation OTMDateRangeFilter

@synthesize maxValue, minValue;

- (id)initWithName:(NSString *)nm key:(NSString *)k {
    self = [super init];
    if (self) {
        [self setName:nm];
        [self setKey:k];
    }

    return self;
}

- (void)addSubviews {
    CGFloat padding = 10;

    CGRect leftFrame = CGRectMake(0,0,122,31);
    CGRect toFrame = CGRectOffset(leftFrame, leftFrame.size.width + padding, 0);
    CGRect rightFrame = CGRectOffset(leftFrame, leftFrame.size.width + padding + 25, 0);

    minValue = [self datePickerTextFieldWithFrame:leftFrame];
    maxValue = [self datePickerTextFieldWithFrame:rightFrame];

    UILabel *toLabel = [[UILabel alloc] initWithFrame:toFrame];
    toLabel.backgroundColor = [UIColor clearColor];
    toLabel.text = @"to";

    [self.view addSubview:minValue];
    [self.view addSubview:maxValue];
    [self.view addSubview:toLabel];
}

- (BOOL) textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)textEntered {
    // The value of the text fields are only set by changing a date picker
    return NO;
}

- (UITextField*)datePickerTextFieldWithFrame:(CGRect)frame {
    UITextField *field = [[AZPastelessTextField alloc] initWithFrame:frame];
    field.borderStyle = UITextBorderStyleRoundedRect;
    field.delegate = self;

    UIDatePicker *picker = [[UIDatePicker alloc] init];
    picker.datePickerMode = UIDatePickerModeDate;
    field.inputView = picker;
    [picker addTarget:self action:@selector(updateTextFieldFromDatePicker:) forControlEvents:UIControlEventValueChanged];

    UIToolbar *toolbar =[[UIToolbar alloc]initWithFrame:CGRectMake(0,0, self.view.frame.size.width,44)];
    toolbar.barStyle = UIBarStyleDefault;

    AZInputViewAccessoryBarButtonItem *clearButton = [[AZInputViewAccessoryBarButtonItem alloc]
                                                      initWithTitle:@"Clear Date"
                                                              style:UIBarButtonItemStylePlain
                                                             target:self
                                                             action:@selector(clearFieldFromDatePicker:)
                                                          inputView:picker];

    UIBarButtonItem *flexibleSpace =[[UIBarButtonItem alloc]
                                     initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                          target:self
                                                          action:nil];

    UIBarButtonItem *closeButton =[[AZInputViewAccessoryBarButtonItem alloc]
                                   initWithTitle:@"Close"
                                           style:UIBarButtonItemStylePlain
                                          target:self
                                          action:@selector(dismisDatePicker:)
                                       inputView:picker];

    [toolbar setItems:@[clearButton,flexibleSpace, closeButton]];

    field.inputAccessoryView = toolbar;

    return field;
}

-(void)clearFieldFromDatePicker:(id)sender {
    if (minValue.inputView == [sender inputView]) {
        minValue.text = @"";
    } else if (maxValue.inputView == [sender inputView]) {
        maxValue.text = @"";
    } else {
        NSLog(@"Expected the sender to be the inputView of the minValue or maxValue field, not %@", sender, nil);
    }
}

-(void)dismisDatePicker:(id)sender {
    if (minValue.inputView == [sender inputView]) {
        [minValue endEditing:YES];
    } else if (maxValue.inputView == [sender inputView]) {
        [maxValue endEditing:YES];
    } else {
        NSLog(@"Expected the sender to be the inputView of the minValue or maxValue field, not %@", sender, nil);
    }
}

-(void)updateTextFieldFromDatePicker:(id)sender {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];

    NSString *newTextFieldText = [dateFormatter stringFromDate:[sender date]];
    if (minValue.inputView == sender) {
        minValue.text = newTextFieldText;
    } else if (maxValue.inputView == sender) {
        maxValue.text = newTextFieldText;
    } else {
        NSLog(@"Expected the sender to be the inputView of the minValue or maxValue field, not %@", sender, nil);
    }
}

- (void)setDelegate:(id)d {
    [super setDelegate:d];
}

- (BOOL)isNonEmptyTextField:(UITextField*)textField {
    NSCharacterSet *charSet = [NSCharacterSet whitespaceCharacterSet];
    NSString *trimmedString = [textField.text stringByTrimmingCharactersInSet:charSet];
    return ![trimmedString isEqualToString:@""];
}

- (BOOL)active {
    if (!minValue || !maxValue) {
        return NO;
    } else {
        return ([self isNonEmptyTextField:minValue] || [self isNonEmptyTextField:maxValue]);
    }
}

- (void)clear {
    minValue.text = nil;
    [((UIDatePicker*)minValue.inputView) setDate:[NSDate new]];
    maxValue.text = nil;
    [((UIDatePicker*)maxValue.inputView) setDate:[NSDate new]];
}

- (void)resignFirstResponder {
    [minValue resignFirstResponder];
    [maxValue resignFirstResponder];
}

- (NSDictionary *)queryParams {
    if ([self active]) {
        NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:OTMEnvironmentDateStringShort];
        if ([self isNonEmptyTextField:minValue]) {
            [params setObject:[dateFormatter stringFromDate:[(UIDatePicker *)minValue.inputView date]]
                       forKey:@"MIN"];
        }
        if ([self isNonEmptyTextField:maxValue]) {
            [params setObject:[dateFormatter stringFromDate:[(UIDatePicker *)maxValue.inputView date]]
                       forKey:@"MAX"];
        }
        return @{self.key: params};
    } else {
        return [NSDictionary dictionary];
    }
}

@end


@implementation OTMTextFilter

@synthesize textBox;

- (id)initWithName:(NSString *)nm key:(NSString *)k {
    self = [super init];
    if (self) {
        [self setName:nm];
        [self setKey:k];
    }

    return self;
}

- (void)addSubviews {
    CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, 31);
    textBox = [[UITextField alloc] initWithFrame:frame];
    textBox.borderStyle = UITextBorderStyleRoundedRect;

    [textBox setDelegate:self];

    [self.view addSubview:textBox];
}

- (void)setDelegate:(id)d {
    [super setDelegate:d];
}

- (BOOL)active {
    return ([textBox.text length] > 0);
}

- (void)clear {
    textBox.text = nil;
}

- (void)resignFirstResponder {
    [textBox resignFirstResponder];
}

- (NSDictionary *)queryParams {
    if ([self active]) {
        return @{self.key: @{ @"LIKE": textBox.text}};
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
    _filters = f.filters;

    [self initFiltersView];
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
    for (OTMFilter *filter in _filters) {
        [filter clear];
    }
}

- (OTMFilters *)generateFilters {
    OTMFilters *filtersobj = [[OTMFilters alloc] init];
    filtersobj.filters = _filters;
    return filtersobj;
}

- (void)initFiltersView {
    for (UIView *v in _filtersView.subviews) {
        [v removeFromSuperview];
    }
    
    CGFloat yMax = 20;
    for (OTMFilter *filter in _filters) {
        filter.delegate = self;
        UIView *v = [filter view];
        v.frame = CGRectMake(0, yMax, v.frame.size.width, v.frame.size.height);
        yMax += v.frame.size.height;
        [_filtersView addSubview:v];
    }
    
    _filtersView.frame = CGRectMake(0, 0, _filtersView.frame.size.width, yMax);
    self.scrollView.contentSize = CGSizeMake(_filtersView.frame.size.width, yMax);
}

@end
