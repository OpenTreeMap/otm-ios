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

#import "OTMUdfCollectionCell.h"
#import "OTMTreeDetailViewController.h"

/**
 * Provide the ability to edit certain UDF collections.
 */
@implementation OTMUdfCollectionEditCellRenderer

NSString * const UdfUpdateNotification = @"UdfUpdateNotification";

/**
 * Collections don't return individual cells. Cells are returned through
 * prepareDiscreteCell but this needs to be implemented to prevent errors.
 */
- (OTMCellSorter *)prepareCell:(NSDictionary *)data
                       inTable:(UITableView *)tableView
{
    return nil;
}

/**
 * Needs to be implemented but we return our data via Notifications so it is
 * just a passthrough.
 */
-(NSDictionary *)updateDictWithValueFromCell:(NSDictionary *)dict {
    return dict;
}

- (id)initWithDataKey:(NSString *)dkey
             typeDict:(NSString *)dict
            sortField:(NSString *)sort
             keyField:(NSString *)keyField
             editable:(BOOL)canEdit
          editableKey:(NSString *)editKey
 editableDefaultValue:(NSString *)defaultValue
{
    self = [super initWithDataKey:dkey editRenderer:nil];
    self.typeDict = [OTMUdfCollectionHelper generateDictFromString:dict];
    self.sortField = sort;
    self.startData = [[NSMutableDictionary alloc] init];
    self.typeKeyField = keyField;

    if (canEdit) {
        self.editableKey = editKey;
        self.editableDefaultValue = defaultValue;
        if ([[[self.typeDict objectForKey:self.editableKey] objectForKey:@"type"] isEqualToString:@"choice"]) {
            self.controller = [[UITableViewController alloc] init];
            self.controller.navigationItem.hidesBackButton = YES;
            self.controller.navigationItem.rightBarButtonItem =
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                          target:self
                                                          action:@selector(done:)];

            __block UITableViewController *tableController = self.controller;
            OTMUdfCollectionEditCellRenderer * __weak weakSelf = self;
            self.clickCallback = ^(UIViewController *aController, NSMutableDictionary *cellData) {
                weakSelf.startData = cellData;
                weakSelf.selected = [cellData objectForKey:editKey];
                [tableController.tableView reloadData];
                [aController.navigationController pushViewController:tableController animated:YES];
            };
            self.controller.tableView.delegate = (id<UITableViewDelegate>)self;
            self.controller.tableView.dataSource = (id<UITableViewDataSource>)self;
        } // Might want to check for other cases here (date) but in our current
        // situation this will only be a choice list.
    } else {
        self.clickCallback = nil;
    }
    return self;
}

- (void)done:(id)sender
{
    NSDictionary *notificationData;
    NSArray *keyFieldArray = [self.typeKeyField componentsSeparatedByString:@"."];
    NSMutableDictionary *updatedUdf;
    updatedUdf = [self.startData mutableCopy];
    [updatedUdf setObject:self.selected forKey:self.editableKey];
    // Just a precaution.
    if ([keyFieldArray count] >= 2) {
        notificationData = @{
                             @"key"   : keyFieldArray[0],
                             @"field" : keyFieldArray[1],
                             @"data"  : [updatedUdf copy]
                             };
    } else {
        // Don't set a Udf if we had invalid data.
        return;
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:UdfUpdateNotification object:notificationData];
    [self.controller.navigationController popViewControllerAnimated:YES];
}

- (OTMCellSorter *)prepareDiscreteCell:(NSDictionary *)data
                               inTable:(UITableView *)tableView
{
    NSArray* keylist = [self.dataKey componentsSeparatedByString:@"."];
    if ([keylist count] > 1) {
        self.type = [[keylist objectAtIndex:0] capitalizedString];
    }

    NSMutableString *cellText = [[NSMutableString alloc] init];
    NSString *sortFieldText;
    NSString *sortData;
    for (id key in data) {
        NSString *type = [[[self typeDict] objectForKey:key] objectForKey:@"type"];
        if (type) {
            if (self.sortField && [self.sortField isEqualToString:key]) {
                sortFieldText = [OTMUdfCollectionHelper stringifyData:[data objectForKey:key] byType:type];
                sortData = [data objectForKey:key];
            } else {
                NSString *text = [OTMUdfCollectionHelper stringifyData:[data objectForKey:key] byType:type];
                [cellText appendString:text];
                [cellText appendString:@"\n"];
            }
        }
    }

    // We can't reuse these cells since they are pre-created and appended to the
    // table. We always have them so there's no benefit to the reuse identifier
    // and attempting to reuse them caused serious rendering issues with the
    // cells.
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];

    // If the cell is clickable, add a chevron.
    if (self.clickCallback) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    UILabel *mainTextLabel = [[UILabel alloc] initWithFrame:
                              CGRectMake(20, cell.contentView.frame.size.height - 10, cell.contentView.frame.size.width / 2, 22)];
    [mainTextLabel setFont:[UIFont systemFontOfSize:15]];

    // If editable make room for the chevron.
    int horizontalOffset = self.clickCallback ? 35 : 20;

    UILabel *sortTextLabel = [[UILabel alloc] initWithFrame:
                              CGRectMake(cell.contentView.frame.size.width / 2 - horizontalOffset, 10, cell.contentView.frame.size.width / 2, 22)];
    [sortTextLabel setFont:[UIFont systemFontOfSize:15]];
    [sortTextLabel setTextColor:[UIColor colorWithRed:0.55f green:0.55f blue:0.55f alpha:1.00f]];
    [sortTextLabel setTextAlignment:UITextAlignmentRight];

    UILabel *typeTextLabel = [[UILabel alloc] initWithFrame:
                              CGRectMake(20, 10, cell.contentView.frame.size.width / 2, 22)];
    [typeTextLabel setFont:[UIFont systemFontOfSize:15]];
    [typeTextLabel setTextColor:[UIColor colorWithRed:0.55f green:0.55f blue:0.55f alpha:1.00f]];


    [typeTextLabel setText:[OTMUdfCollectionHelper typeLabelFromType:self.type]];
    [sortTextLabel setText:sortFieldText];

    CGSize textSize = {
        cell.contentView.frame.size.width / 2,   // limit width
        20000.0  // and height of text area
    };

    CGSize size = [cellText sizeWithFont:[UIFont systemFontOfSize:15.0] constrainedToSize:textSize
                           lineBreakMode:NSLineBreakByWordWrapping];
    CGRect labelFrame = [mainTextLabel frame];
    labelFrame.size.height = size.height;
    [mainTextLabel setFrame:labelFrame];
    [mainTextLabel setText:cellText];
    mainTextLabel.numberOfLines = 0;
    mainTextLabel.lineBreakMode = NSLineBreakByWordWrapping;

    [cell.contentView addSubview:mainTextLabel];
    [cell.contentView addSubview:typeTextLabel];
    [cell.contentView addSubview:sortTextLabel];

    CGFloat totalHeight = mainTextLabel.frame.size.height + typeTextLabel.frame.size.height + 20;

    return [[OTMCellSorter alloc] initWithCell:cell
                                       sortKey:self.sortField
                                      sortData:sortData
                                  originalData:[data mutableCopy]
                                        height:totalHeight
                                 clickCallback:self.clickCallback];
}

/**
 * Table delegate methods.
 */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *choices = [[self.typeDict objectForKey:self.editableKey] objectForKey:@"choices"];
    return [choices count];
}

- (void)tableView:(UITableView *)tblView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *choices = [[self.typeDict objectForKey:self.editableKey] objectForKey:@"choices"];
    self.selected = [choices objectAtIndex:indexPath.row];
    [tblView reloadData];
}

- (UITableViewCell *)tableView:(UITableView *)tblView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *choices = [[self.typeDict objectForKey:self.editableKey] objectForKey:@"choices"];
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    cell.textLabel.text = [choices objectAtIndex:indexPath.row];
    if ([self.selected isEqualToString:[choices objectAtIndex:indexPath.row]]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    return cell;
}

@end


/**
 * Creates an Add More button that makes UDF collections based on a data
 * definition.
 */
@implementation OTMUdfAddMoreRenderer

NSString * const UdfDataChangedForStepNotification = @"UdfDataChangedForStepNotification";

- (NSDictionary *)updateDictWithValueFromCell:(NSDictionary *)dict {
    // Don't do anything here. We should have already added the data via a
    // notification.
    return dict;
}

- (OTMCellSorter *)prepareCell:(NSDictionary *)data inTable:(UITableView *)tableView
{
    self.tableView = tableView;
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    UIButton *button = [[UIButton alloc] init];
    [button addTarget:self action:@selector(addMoreViewStackToTable:) forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:@"Add New" forState:UIControlStateNormal];
    [button setTitleColor:[[OTMEnvironment sharedEnvironment] primaryColor] forState:UIControlStateNormal];
    // Make the button fill the cell so you can't miss it.
    button.frame = CGRectMake(0, 0, cell.frame.size.width, cell.frame.size.height);
    [cell addSubview:button];
    return [[OTMCellSorter alloc] initWithCell:cell
                                       sortKey:nil
                                      sortData:nil
                                        height:cell.frame.size.height
                                 clickCallback:nil];
}

- (id)initWithDataStructure:(NSArray *)dataArray
                      field:(NSString *)field
                        key:(NSString *)key
                displayName:(NSString *)displayName
{
    self = [super init];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveNotification:)
                                                 name:UdfDataChangedForStepNotification
                                               object:nil];
    if (self) {
        self.steps = dataArray;
        self.currentSteps = self.steps;
        self.displayName = displayName;
        self.field = field;
        self.key = key;
        self.preparedNewUdf = [[NSMutableDictionary alloc] init];
        self.step = 0;
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)receiveNotification:(NSNotification *)notification
{
    if (self.step == 0) {
        self.preparedNewUdf = [[NSMutableDictionary alloc] init];
    }
    NSDictionary *notificationData = [notification object];
    [self.preparedNewUdf setObject:[notificationData objectForKey:@"data"] forKey:[notificationData objectForKey:@"key"]];
}

- (void) addMoreViewStackToTable:(id)sender
{

    self.navController = [[UINavigationController alloc] init];
    self.step = 0;
    self.currentSteps = self.steps;
    self.preparedNewUdf = [[NSMutableDictionary alloc] init];

    BOOL finalStep = NO;
    // If the next step is the default, and also the last step then we should be
    // done after this one.
    if ([self.currentSteps count] == 2) {
        NSDictionary *next = [self.currentSteps objectAtIndex:(self.step + 1)];
        if ([next objectForKey:@"default"]) {
            finalStep = YES;
        }
    } else if (self.step == ([self.currentSteps count] - 1)) {
        finalStep = YES;
    }

    UIViewController *firstViewController = [self generateViewControllerFromDict:[self.currentSteps objectAtIndex:self.step]];
    [firstViewController setTitle:[[self.currentSteps objectAtIndex:self.step] objectForKey:@"name"]];
    [self.navController pushViewController:firstViewController animated:NO];

    [[firstViewController navigationItem]
     setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                           style:UIBarButtonItemStyleBordered
                                                          target:self
                                                          action:@selector(cancelEditing:)]];
    if (finalStep) {
        [[firstViewController navigationItem]
         setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                style:UIBarButtonItemStyleBordered
                                                               target:self
                                                               action:@selector(done:)]];
    } else {
        [[firstViewController navigationItem]
         setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Next"
                                                                style:UIBarButtonItemStyleBordered
                                                               target:self
                                                               action:@selector(nextStep:)]];
        [[[firstViewController navigationItem] rightBarButtonItem] setEnabled:NO];

    }
    [self.originatingDelegate presentModalViewController:self.navController animated:YES];
}

- (void)done:(id)sender
{
    NSArray *fieldData = [[self.preparedNewUdf objectForKey:@"Type"] componentsSeparatedByString:@"."];
    [self.preparedNewUdf removeObjectForKey:@"Type"];

    NSDictionary *notificationData;
    // Just a precaution.
    if ([fieldData count] >= 2) {
        notificationData = @{
                             @"key"   : fieldData[0],
                             @"field" : fieldData[1],
                             @"data"  : self.preparedNewUdf
                             };
    } else {
        // Don't set a Udf if we had invalid data.
        return;
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:UdfNewDataCreatedNotification object:notificationData];
    // Reset.
    self.preparedNewUdf = [[NSMutableDictionary alloc] init];
    [self.originatingDelegate dismissModalViewControllerAnimated:YES];
}

- (void) cancelEditing:(id)sender
{
    // Reset.
    self.preparedNewUdf = [[NSMutableDictionary alloc] init];
    [self.originatingDelegate dismissModalViewControllerAnimated:YES];
}

- (void) back:(id)sender
{
    self.step--;
    if (self.step == 0) {
        self.currentSteps = self.steps;
    }
    [self.navController popViewControllerAnimated:YES];
}

- (void) nextStep:(id)sender
{
    self.step++;

    // If this is the default step skip to the next one.
    if ([[self.currentSteps objectAtIndex:self.step] objectForKey:@"default"]) {
        // Make sure there is another step ahead of us. This should never happen
        // but it is good to be defensive.
        if ([self.steps count] - 1 == self.step + 1) {
            self.step++;
        }
    }

    UIViewController *nextViewController = [self generateViewControllerFromDict:[self.currentSteps objectAtIndex:self.step]];
    [nextViewController setTitle:[[self.currentSteps objectAtIndex:self.step] objectForKey:@"name"]];
    [self.navController pushViewController:nextViewController animated:NO];
}

- (UIViewController *)generateViewControllerFromDict:(NSDictionary *)dict
{
    UIViewController *controller;

    if ([[dict objectForKey:@"type"] isEqualToString:@"choice"]) {
        OTMUdfChoiceTableViewController *viewController = [[OTMUdfChoiceTableViewController alloc] initWithKey:[dict objectForKey:@"name"]];
        NSArray *choices = [[NSArray alloc] initWithArray:[dict objectForKey:@"choices"]];
        [viewController setChoices:choices];
        controller = (UIViewController *)viewController;
        [self setControllerButtons:controller withNextEnabled:NO];

    } else if ([[dict objectForKey:@"type"] isEqualToString:@"date"]) {
        UIViewController *viewController = [[UIViewController alloc] init];
        UIDatePicker *datePicker = [[UIDatePicker alloc] init];
        datePicker.datePickerMode = UIDatePickerModeDate;
        [viewController.view addSubview:datePicker];
        [datePicker addTarget:self action:@selector(setDateForKey:) forControlEvents:UIControlEventValueChanged];
        controller = viewController;

        // For dates we initialize the picked date at the current date so we
        // need to enable the next button. Because of timing issues with the
        // drawing of the view and the sending of the message we just set it as
        // endabled when we dray it since we know that we're going to be setting
        // it with a default.
        [self setControllerButtons:controller withNextEnabled:YES];
        [self setDateForKey:datePicker];

    } else if ([[dict objectForKey:@"type"] isEqualToString:@"udf_keyed_grouping"]) {
        NSMutableArray *newSteps = [[[[self.steps objectAtIndex:self.step] objectForKey:@"choices"] objectForKey:[self.preparedNewUdf objectForKey:@"Type"]] mutableCopy];
        NSDictionary *firstStep = [self.steps objectAtIndex:0];
        [newSteps insertObject:firstStep atIndex:0];
        self.currentSteps = [newSteps copy];
        controller = [self generateViewControllerFromDict:[self.currentSteps objectAtIndex:self.step]];
    }

    return controller;
}

- (void)setControllerButtons:(UIViewController *)controller withNextEnabled:(BOOL)enabled
{
    BOOL finalStep = NO;
    // If we're on the second to last step...
    if ([self.currentSteps count] == self.step + 2) {
        NSDictionary *next = [self.currentSteps objectAtIndex:(self.step + 1)];
        // ... and the next step is the default, then we should be done after
        // this one.
        if ([next objectForKey:@"default"]) {
            finalStep = YES;
            NSDictionary *notificationData = @{
                                               @"key" : [next objectForKey:@"name"],
                                               @"data" : [next objectForKey:@"default"]
                                               };
            [[NSNotificationCenter defaultCenter] postNotificationName:UdfDataChangedForStepNotification object:notificationData];
        }
    } else if (self.step == ([self.currentSteps count] - 1)) {
        finalStep = YES;
    }

    [[controller navigationItem]
     setLeftBarButtonItem:[[UIBarButtonItem alloc]
                           initWithTitle:@"Back"
                           style:UIBarButtonItemStyleBordered
                           target:self
                           action:@selector(back:)]];

    if (finalStep) {
        [[controller navigationItem]
         setRightBarButtonItem:[[UIBarButtonItem alloc]
                                initWithTitle:@"Done"
                                style:UIBarButtonItemStyleBordered
                                target:self
                                action:@selector(done:)]];
    } else {
        [[controller navigationItem]
         setRightBarButtonItem:[[UIBarButtonItem alloc]
                                initWithTitle:@"Next"
                                style:UIBarButtonItemStyleBordered
                                target:self
                                action:@selector(nextStep:)]];

    }
    if (!enabled) {
        [[[controller navigationItem] rightBarButtonItem] setEnabled:NO];
    }
}

- (void)setDateForKey:(id)sender
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSString *dateText = [dateFormatter stringFromDate:[(UIDatePicker *)sender date]];
    NSString *key = [[self.currentSteps objectAtIndex:self.step] objectForKey:@"name"];
    NSDictionary *notificationData = @{
                                       @"key" : key,
                                       @"data" : dateText
                                       };
    [[NSNotificationCenter defaultCenter] postNotificationName:UdfDataChangedForStepNotification object:notificationData];
}

@end


@implementation OTMUdfChoiceTableViewController

@synthesize choices, choice;

- (id)initWithKey:(NSString *)key
{
    self = [super init];
    if (self) {
        self.key = key;
    }
    return self;
}

- (void)setChoices:(NSArray *)choicesArray {
    choices = [[NSArray alloc] initWithArray:choicesArray];
    self.choiceLabels = [self translateKeyLabels:choices];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.choices count];
}

- (UITableViewCell *)tableView:(UITableView *)tblView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UdfChoiceCell"];
    cell.textLabel.text = [self.choiceLabels objectAtIndex:indexPath.row];
    if ([[self.choices objectAtIndex:indexPath.row] isEqualToString:self.choice]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    return cell;
}

- (void)tableView:(UITableView *)tblView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [[[self navigationItem] rightBarButtonItem] setEnabled:YES];
    self.choice = [self.choices objectAtIndex:indexPath.row];
    NSDictionary *notificationData = @{
                                       @"key" : self.key,
                                       @"data": self.choice
                                       };
    [[NSNotificationCenter defaultCenter] postNotificationName:UdfDataChangedForStepNotification object:notificationData];
    [self.tableView reloadData];
}

- (NSArray *)translateKeyLabels:(NSArray *)choiceKeys
{
    NSMutableArray *humanReadableChoices = [[NSMutableArray alloc] init];
    NSDictionary *translations = @{
                                   @"tree.udf:Stewardship": @"Tree",
                                   @"plot.udf:Stewardship": @"Planting Site",
                                   @"tree.udf:Alerts"     : @"Tree",
                                   @"plot.udf:Alerts"     : @"Planting Site",
                                   };

    for (NSString *choiceKey in choiceKeys) {
        // If this key has labels, then set them otherwise return the original
        // value.
        if ([translations objectForKey:choiceKey]) {
            [humanReadableChoices addObject:[translations objectForKey:choiceKey]];
        } else {
            [humanReadableChoices addObject:choiceKey];
        }
    }
    return humanReadableChoices;
}

@end


/**
 * Handles creation and rendering of collections of UDFs
 */
@implementation OTMCollectionUDFCellRenderer

- (OTMCellSorter *)prepareCell:(NSDictionary *)data
                       inTable:(UITableView *)tableView
{
    return nil;
}

- (OTMCellSorter *)prepareDiscreteCell:(NSDictionary *)data
                               inTable:(UITableView *)tableView
{
    NSArray* keylist = [self.dataKey componentsSeparatedByString:@"."];
    if ([keylist count] > 1) {
        self.type = [[keylist objectAtIndex:0] capitalizedString];
    }

    NSMutableString *cellText = [[NSMutableString alloc] init];
    NSString *sortFieldText;
    NSString *sortData;
    for (id key in data) {
        NSString *type = [[[self typeDict] objectForKey:key] objectForKey:@"type"];
        if (type) {
            if (self.sortField && [self.sortField isEqualToString:key]) {
                sortFieldText = [OTMUdfCollectionHelper stringifyData:[data objectForKey:key] byType:type];
                sortData = [data objectForKey:key];
            } else {
                NSString *text = [OTMUdfCollectionHelper stringifyData:[data objectForKey:key] byType:type];
                [cellText appendString:text];
                [cellText appendString:@"\n"];
            }
        }
    }

    // We can't reuse these cells since they are pre-created and appended to the
    // table. We always have them so there's no benefit to the reuse identifier
    // and attempting to reuse them caused serious rendering issues with the
    // cells.
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];

    UILabel *mainTextLabel = [[UILabel alloc] initWithFrame:
                              CGRectMake(20, cell.contentView.frame.size.height - 10, cell.contentView.frame.size.width / 2, 22)];
    [mainTextLabel setFont:[UIFont systemFontOfSize:15]];

    UILabel *sortTextLabel = [[UILabel alloc] initWithFrame:
                              CGRectMake(cell.contentView.frame.size.width / 2 - 20, 10, cell.contentView.frame.size.width / 2, 22)];
    [sortTextLabel setFont:[UIFont systemFontOfSize:15]];
    [sortTextLabel setTextColor:[UIColor colorWithRed:0.55f green:0.55f blue:0.55f alpha:1.00f]];
    [sortTextLabel setTextAlignment:UITextAlignmentRight];

    UILabel *typeTextLabel = [[UILabel alloc] initWithFrame:
                              CGRectMake(20, 10, cell.contentView.frame.size.width / 2, 22)];
    [typeTextLabel setFont:[UIFont systemFontOfSize:15]];
    [typeTextLabel setTextColor:[UIColor colorWithRed:0.55f green:0.55f blue:0.55f alpha:1.00f]];


    [typeTextLabel setText:[OTMUdfCollectionHelper typeLabelFromType:self.type]];
    [sortTextLabel setText:sortFieldText];

    CGSize textSize = {
        cell.contentView.frame.size.width / 2,   // limit width
        20000.0  // and height of text area
    };

    CGSize size = [cellText sizeWithFont:[UIFont systemFontOfSize:15.0] constrainedToSize:textSize lineBreakMode:NSLineBreakByWordWrapping];
    CGRect labelFrame = [mainTextLabel frame];
    labelFrame.size.height = size.height;
    [mainTextLabel setFrame:labelFrame];
    [mainTextLabel setText:cellText];
    mainTextLabel.numberOfLines = 0;
    mainTextLabel.lineBreakMode = NSLineBreakByWordWrapping;

    [cell.contentView addSubview:mainTextLabel];
    [cell.contentView addSubview:typeTextLabel];
    [cell.contentView addSubview:sortTextLabel];

    CGFloat totalHeight = mainTextLabel.frame.size.height + typeTextLabel.frame.size.height + 20;

    return [[OTMCellSorter alloc] initWithCell:cell
                                       sortKey:self.sortField
                                      sortData:sortData
                                        height:totalHeight
                                 clickCallback:nil];
}

- (id)initWithDataKey:(NSString *)dkey
             typeDict:(NSString *)dict
            sortField:(NSString *)sort
         editRenderer:(OTMEditDetailCellRenderer *)edit
      addMoreRenderer:(OTMUdfAddMoreRenderer *)more
{
    self = [super initWithDataKey:dkey editRenderer:nil];
    self.typeDict = [OTMUdfCollectionHelper generateDictFromString:dict];
    self.sortField = sort;
    self.editCellRenderer = edit;
    return self;
}

@end


/**
 * Helper class to store common static functions that are shared by the
 * UDFCollectionRenderer and the UDFEditCollectionRenderer.
 */
@implementation OTMUdfCollectionHelper

+ (NSDictionary *)generateDictFromString:(NSString *)dictString
{
    NSArray *typesArray = [dictString copy];

    // Making the assumption that in a UDF there cannot be multiple fields with
    // the same name.
    NSMutableDictionary *typesDict = [[NSMutableDictionary alloc] init];
    for (id type in typesArray) {
        [typesDict setObject:type forKey:[type objectForKey:@"name"]];
    }
    return [typesDict copy];
}

+ (NSString *)stringifyData:(id)data byType:(NSString *)type
{
    NSString *result;
    if ([type isEqualToString:@"date"]) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd' 'HH':'mm':'ss'"];
        NSDate *date =[dateFormatter dateFromString:data];

        // Newly set dates have a different format so we need to account for
        // them.
        if (!date) {
            [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'"];
            date =[dateFormatter dateFromString:data];
        }

        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
        return [dateFormatter stringFromDate:date];

    } else if ([type isEqualToString:@"choice"]) {
        result = data;
    } else {
        result = @"";
    }
    return result;
}

/**
 * A wrapper around a dictionary to provide human readable names for types of
 * stewardships and alerts.
 *
 * "Plot" -> "Planting Site"
 */
+ (NSString *)typeLabelFromType:(NSString *)type
{
    NSArray *keys = [[NSArray alloc] initWithObjects:@"tree", @"plot", nil];
    NSArray *labels = [[NSArray alloc] initWithObjects:@"Tree", @"Planting Site", nil];
    NSDictionary *keyLabels = [[NSDictionary alloc] initWithObjects:labels forKeys:keys];

    // Work against the case insensive string.
    NSString *typeLabel = [keyLabels objectForKey:[type lowercaseString]];
    // If no match return the original text.
    if (!typeLabel) {
        typeLabel = type;
    }
    return typeLabel;
}

@end
