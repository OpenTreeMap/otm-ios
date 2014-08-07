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

#import "OTMDetailCellRenderer.h"
#import "OTMFormatter.h"
#import "OTMUser.h"
#import "OTMTreeDetailViewController.h"

@implementation OTMDetailCellRenderer

@synthesize dataKey, editCellRenderer, newCellBlock, clickCallback, cellHeight, detailDataKey, ownerDataKey;

- (id)init {
    self = [super init];

    if (self) {
        self.cellHeight = 44;
    }

    return self;
}

- (id)initWithDataKey:(NSString *)dkey  {
    return [self initWithDataKey:dkey editRenderer:nil];
}

-(id)initWithDataKey:(NSString *)dkey editRenderer:(OTMEditDetailCellRenderer *)edit {
    self = [self init];

    if (self) {
        self.dataKey = dkey;
        self.editCellRenderer = edit;
    }

    return self;
}

- (OTMCellSorter *)prepareCell:(NSDictionary *)data inTable:(UITableView *)tableView
{
    ABSTRACT_METHOD_BODY
}

- (NSArray *)prepareAllCells:(NSDictionary *)data inTable:(UITableView *)tableView withOriginatingDelegate:(UINavigationController *)delegate
{
    self.originatingDelegate = delegate;
    NSMutableArray *cells = [[NSMutableArray alloc] init];
    id elmt = [data decodeKey:self.dataKey];
    OTMCellSorter *sorterCell;
    if ([elmt isKindOfClass:[NSArray class]]) {
        for (id dataElement in elmt) {
            sorterCell = (OTMCellSorter *)[self prepareDiscreteCell:dataElement inTable:tableView];
            [cells addObject:sorterCell];
        }
    } else {
        sorterCell = (OTMCellSorter *)[self prepareCell:data inTable:tableView];
        if (sorterCell) {
            [cells addObject:sorterCell];
        } else {
            NSLog(@"No sorter cell found.");
        }
    }
    return [cells copy];
}

- (OTMCellSorter *)prepareDiscreteCell:(NSDictionary *)data inTable:(UITableView *)tableView
{
    ABSTRACT_METHOD_BODY
}

@end

#define kOTMLabelDetailCellRendererCellId @"kOTMLabelDetailCellRendererCellId"

@implementation OTMLabelDetailCellRenderer

-(id)initWithDataKey:(NSString *)dkey
        editRenderer:(OTMEditDetailCellRenderer *)edit
               label:(NSString *)labeltxt
           formatter:(OTMFormatter *)fmt
              isDate:(BOOL)dType
{
    self = [super initWithDataKey:dkey editRenderer:edit];

    if (self) {
        _label = labeltxt;
        _formatter = fmt;
        _isDateField = dType;
    }

    return self;
}

- (OTMCellSorter *)prepareCell:(NSDictionary *)data inTable:(UITableView *)tableView
{
    OTMDetailTableViewCell *detailcell = [tableView dequeueReusableCellWithIdentifier:kOTMLabelDetailCellRendererCellId];

    if (detailcell == nil) {
        detailcell = [[OTMDetailTableViewCell alloc] initWithStyle:UITableViewCellStyleValue2
                                                   reuseIdentifier:kOTMLabelDetailCellRendererCellId];
    }

    id value = [data decodeKey:self.dataKey];

    NSDictionary *pendingEditDict = [data objectForKey:@"pending_edits"];
    if (pendingEditDict) {
        if ([pendingEditDict objectForKey:self.dataKey] || [pendingEditDict objectForKey:self.ownerDataKey]) {
            detailcell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            if ([pendingEditDict objectForKey:self.ownerDataKey]) {
                NSDictionary *latestOwnerEdit = [[[pendingEditDict objectForKey:self.ownerDataKey] objectForKey:@"pending_edits"] objectAtIndex:0];
                value = [[latestOwnerEdit objectForKey:@"related_fields"] objectForKey:self.dataKey];
            } else {
                value = [[pendingEditDict objectForKey:self.dataKey] objectForKey:@"latest_value"];
            }
        } else {
            detailcell.accessoryType = UITableViewCellAccessoryNone;
        }
    }

    NSString *displayValue;

    if (_formatter != nil) {
        displayValue = [_formatter format:[value floatValue]];
    } else if (_isDateField) {
        displayValue = [detailcell formatHumanReadableDateStringFromString:value];
    } else {
        displayValue = [value description];
    }

    detailcell.fieldLabel.text = self.label;
    detailcell.fieldValue.text = displayValue;


    return [[OTMCellSorter alloc] initWithCell:detailcell
                                       sortKey:nil
                                      sortData:nil
                                        height:self.cellHeight
                                 clickCallback:nil];
}

@end

@implementation OTMBenefitsDetailCellRenderer


- (id)initWithModel:(NSString *)model key:(NSString *)key {
    self = [super initWithDataKey:nil];

    if (self) {
        _cell = [OTMBenefitsTableViewCell loadFromNib];
        self.cellHeight = _cell.frame.size.height;
        self.model = model;
        self.key = key;
    }

    return self;
}

- (OTMCellSorter *)prepareCell:(NSDictionary *)data inTable:(UITableView *)tableView
{
    NSDictionary *allBenefits = [data objectForKey:@"benefits"];
    NSDictionary *modelBenefits = [allBenefits objectForKey:self.model];
    NSDictionary *benefit = [modelBenefits objectForKey:self.key];

    self.cell.benefitName.text = benefit[@"label"];

    NSString *value = [benefit objectForKey:@"value"];
    NSString *unit = [benefit objectForKey:@"unit"];
    if (value) {
        self.cell.benefitValue.text = [NSString stringWithFormat:@"%@ %@", value, unit];
    } else {
        self.cell.benefitValue.text = @"";
    }

    if ([benefit objectForKey:@"currency_saved"]) {
        self.cell.benefitDollarAmt.text = [NSString stringWithFormat:@"%@ saved", [benefit objectForKey:@"currency_saved"]];
    } else {
        self.cell.benefitDollarAmt.text = @"";
    }
    return [[OTMCellSorter alloc] initWithCell:_cell
                                       sortKey:nil
                                      sortData:nil
                                        height:self.cellHeight
                                 clickCallback:nil];
}

@end


@implementation OTMEditDetailCellRenderer : OTMDetailCellRenderer

- (id)initWithDataKey:(NSString *)dkey  {
    return [super initWithDataKey:dkey];
}

- (NSDictionary *)updateDictWithValueFromCell:(NSDictionary *)dict {
    ABSTRACT_METHOD_BODY
}

@end

@implementation OTMLabelEditDetailCellRenderer

@synthesize label, updatedString, keyboard;

- (id)initWithDataKey:(NSString *)dkey
                label:(NSString *)displayLabel
             keyboard:(UIKeyboardType)kboard
            formatter:(OTMFormatter *)formatter isDate:(BOOL)dType
{
    self = [super initWithDataKey:dkey];

    if (self) {
        self.formatter = formatter;
        self.keyboard = kboard;
        self.label = displayLabel;
        self.inited = NO;
        self.isDateField = dType;

    }

    return self;
}

- (void)tableViewCell:(UITableViewCell *)tblViewCell
           textField:(UITextField *)field
      updatedToValue:(NSString *)v
{
    if ([v isEqualToString:@""]) {
        self.updatedString = nil;
    } else {
        self.updatedString = v;
    }
}

- (NSDictionary *)updateDictWithValueFromCell:(NSDictionary *)dict {
    if (updatedString) {
        [dict setObject:updatedString forEncodedKey:self.dataKey];
        updatedString = nil;
    }

    return dict;
}


#define kOTMLabelDetailEditCellRendererCellId @"kOTMLabelDetailEditCellRendererCellId"

- (OTMCellSorter *)prepareCell:(NSDictionary *)data
                       inTable:(UITableView *)tableView
{
    OTMDetailTableViewCell *detailcell = [tableView dequeueReusableCellWithIdentifier:kOTMLabelDetailEditCellRendererCellId];

    if (detailcell == nil) {
        detailcell = [[OTMDetailTableViewCell alloc] initWithStyle:UITableViewCellStyleValue2
                                                   reuseIdentifier:kOTMLabelDetailEditCellRendererCellId];
    }

    if (!self.inited) {
        detailcell.delegate = self;
        detailcell.editFieldValue.hidden = NO;
        detailcell.fieldValue.hidden = YES;
        detailcell.keyboardType = keyboard;

        id value = [data decodeKey:self.dataKey];
        NSString *disp = @"";

        if (value != nil) {
            disp = [_formatter formatWithoutUnit:[value floatValue]];
        }

        if (self.isDateField) {
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyy-MM-dd"];
            NSDate *originalDate =[dateFormatter dateFromString:value];
            [detailcell setDatePickerInputWithInitialDate:originalDate];
            disp = [detailcell formatHumanReadableDateStringFromDate:originalDate];

        }

        detailcell.editFieldValue.text = disp;
        detailcell.fieldLabel.text = self.label;

        /**
         * Edit cells don't have a fieldValue like the normal detail cell. We
         * want nice alignment so offset the frame for the name to take up the
         * place that the value was holding.
         * To see where these numbers are coming from
         * @see OTMDetailTableViewCell
         * @see - (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
         */
        detailcell.fieldLabel.frame = CGRectOffset(detailcell.fieldLabel.frame, 0, self.cellHeight/4 - 1);

        detailcell.unitLabel.text = _formatter.label;
        self.inited = YES;

    }

    return [[OTMCellSorter alloc] initWithCell:detailcell
                                       sortKey:nil
                                      sortData:nil
                                        height:self.cellHeight
                                 clickCallback:nil];
}

@end

@implementation OTMDBHEditDetailCellRenderer

- (id)initWithDataKey:(NSString *)dkey formatter:(OTMFormatter *)formatter {
    self = [super initWithDataKey:dkey];

    if (self) {
        _cell = [OTMDBHTableViewCell loadFromNib];
        _cell.delegate = self;
        self.cellHeight = _cell.frame.size.height;
        _formatter = formatter;
        self.inited = NO;
    }

    return self;
}

- (void)tableViewCell:(UITableViewCell *)tblViewCell textField:(UITextField *)field updatedToValue:(NSString *)v {

    if (v == nil || [v length] == 0) {
        self.cell.diameterTextField.text = self.cell.circumferenceTextField.text = @"";
    } else if (field == self.cell.circumferenceTextField) {
        CGFloat circ = [v floatValue];
        NSString *diam = [NSString stringWithFormat:@"%0.*f", _formatter.digits, circ / M_PI];

        self.cell.diameterTextField.text = diam;
    } else {
        CGFloat diam = [v floatValue];
        NSString *circ = [NSString stringWithFormat:@"%0.*f", _formatter.digits, diam * M_PI];

        self.cell.circumferenceTextField.text = circ;
    }
}

- (NSDictionary *)updateDictWithValueFromCell:(NSDictionary *)dict {
    NSString *newDBH = self.cell.diameterTextField.text;
    if (newDBH && [newDBH length] > 0) {
        CGFloat dispValue = [self.cell.diameterTextField.text floatValue];

        [dict setObject:[NSNumber numberWithFloat:dispValue]
          forEncodedKey:self.dataKey];
    }

    return dict;
}

#define OTMLabelDetailEditCellRendererCellId @"kOTMLabelDetailEditCellRendererCellId"

- (OTMCellSorter *)prepareCell:(NSDictionary *)data inTable:(UITableView *)tableView
{
    if (!self.inited) {
        id elmt = [data decodeKey:self.dataKey];

        NSString *disp = @"";
        if (elmt != nil) {
            CGFloat dispValue = [elmt floatValue];
            disp = [NSString stringWithFormat:@"%.*f", _formatter.digits, dispValue];
        }

        self.cell.diameterTextField.text = disp;
        [self tableViewCell:nil
                  textField:self.cell.diameterTextField
             updatedToValue:self.cell.diameterTextField.text];

        self.inited = YES;
    }

    return [[OTMCellSorter alloc] initWithCell:_cell
                                       sortKey:nil
                                      sortData:nil
                                        height:self.cellHeight
                                 clickCallback:nil];
}

@end

@implementation OTMUdfCollectionEditCellRenderer

- (OTMCellSorter *)prepareCell:(NSDictionary *)data
                       inTable:(UITableView *)tableView
{
    return nil;
}

- (NSDictionary *)updateDictWithValueFromCell:(NSDictionary *)dict {
    return dict;
}

- (id)initWithDataKey:(NSString *)dkey
             typeDict:(NSString *)dict
            sortField:(NSString *)sort
{
    self = [super initWithDataKey:dkey editRenderer:nil];
    [self generateDictFromString:dict];
    [self setHeight];
    self.sortField = sort;
    self.clickCallback = nil;
    return self;
}

- (void)generateDictFromString:(NSString *)dictString
{
    NSArray *typesArray = [dictString copy];

    // Making the assumption that in a UDF there cannot be multiple fields with
    // the same name.
    NSMutableDictionary *typesDict = [[NSMutableDictionary alloc] init];
    for (id type in typesArray) {
        [typesDict setObject:type forKey:[type objectForKey:@"name"]];
    }
    self.typeDict = [typesDict copy];
}

- (void)setHeight
{
    CGFloat height = self.cellHeight;
    // For each row of text add 13 to the cell height to accomodate the height
    // of the line.
    height += 13 * ([self.typeDict count] - 1);
    // If we have a sort field (which is displayed on the right side of the cell
    // Drop the size to accomodate a line having been removed.
    if (self.sortField) {
        height -= 13;
    }
    self.cellHeight = height;
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
                sortFieldText = [self stringifyData:[data objectForKey:key] byType:type];
                sortData = [data objectForKey:key];
            } else {
                NSString *text = [self stringifyData:[data objectForKey:key] byType:type];
                [cellText appendString:text];
                [cellText appendString:@"\n"];
            }
        }
    }

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


    [typeTextLabel setText:[self typeLabelFromType:self.type]];
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
                                      sortData:sortData height:totalHeight
                                 clickCallback:nil];
}

- (NSString *)typeLabelFromType:(NSString *)type
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

- (NSString *)stringifyData:(id)data byType:(NSString *)type
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

@end

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

    UIViewController *firstViewController = [self generateViewControllerFromDict:[self.currentSteps objectAtIndex:self.step]];
    [firstViewController setTitle:[[self.currentSteps objectAtIndex:self.step] objectForKey:@"name"]];
    [self.navController pushViewController:firstViewController animated:NO];

    [[firstViewController navigationItem]
        setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                              style:UIBarButtonItemStyleBordered
                                                             target:self
                                                             action:@selector(cancelEditing:)]];
    if (self.step == [self.currentSteps count] - 1) {
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
    [[controller navigationItem]
     setLeftBarButtonItem:[[UIBarButtonItem alloc]
                           initWithTitle:@"Back"
                           style:UIBarButtonItemStyleBordered
                           target:self
                           action:@selector(back:)]];

    if (self.step == ([self.currentSteps count] - 1)) {
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
    cell.textLabel.text = [self.choices objectAtIndex:indexPath.row];
    if ([[self.choices objectAtIndex:indexPath.row] isEqualToString:self.choice]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    return cell;
}

- (void)tableView:(UITableView *)tblView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [[[self navigationItem] rightBarButtonItem] setEnabled:YES];
    UITableViewCell *cell = [tblView cellForRowAtIndexPath:indexPath];
    self.choice = cell.textLabel.text;
    NSDictionary *notificationData = @{
                           @"key" : self.key,
                           @"data": self.choice
                           };
    [[NSNotificationCenter defaultCenter] postNotificationName:UdfDataChangedForStepNotification object:notificationData];
    [self.tableView reloadData];
}

@end

@implementation OTMStaticClickCellRenderer

#define kOTMDetailEditSpeciesCellRendererCellId @"kOTMDetailEditSpeciesCellRendererCellId"

@synthesize name, data, defaultName;

- (id)initWithKey:(NSString *)key clickCallback:(Function1v)aCallback {
    return [self initWithName:nil key:key clickCallback:aCallback];
}

- (id)initWithName:(NSString *)aName
               key:(NSString *)key
     clickCallback:(Function1v)aCallback
{
    self = [super init];

    if (self) {
        self.dataKey = key;
        data = nil;
        name = aName;

        self.clickCallback = aCallback;
    }

    return self;
}

- (OTMCellSorter *)prepareCell:(NSDictionary *)renderData
                       inTable:(UITableView *)tableView
{
    UITableViewCell *detailcell = [tableView dequeueReusableCellWithIdentifier:kOTMDetailEditSpeciesCellRendererCellId];

    if (detailcell == nil) {
        detailcell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                            reuseIdentifier:kOTMDetailEditSpeciesCellRendererCellId];
    }

    if (name == nil) {
        NSString *val = [renderData decodeKey:self.dataKey];

        if (val == nil || [val length] == 0) {
            val = self.defaultName;
        }

        detailcell.textLabel.text = val;
        // If the detailDataKey is nil or it is not present in the data, setting the
        // label text to nil is the correct behavior
        detailcell.detailTextLabel.text = [renderData decodeKey:self.detailDataKey];
    } else {
        detailcell.textLabel.text = name;
        detailcell.detailTextLabel.text = nil;
    }

    detailcell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    return [[OTMCellSorter alloc] initWithCell:detailcell
                                       sortKey:nil
                                      sortData:nil
                                        height:self.cellHeight
                                 clickCallback:self.clickCallback];
}

- (NSDictionary *)updateDictWithValueFromCell:(NSDictionary *)dict {
    return dict;
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
                sortFieldText = [self stringifyData:[data objectForKey:key] byType:type];
                sortData = [data objectForKey:key];
            } else {
                NSString *text = [self stringifyData:[data objectForKey:key] byType:type];
                [cellText appendString:text];
                [cellText appendString:@"\n"];
            }
        }
    }

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


    [typeTextLabel setText:[self typeLabelFromType:self.type]];
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

- (NSString *)stringifyData:(id)data byType:(NSString *)type
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
- (NSString *)typeLabelFromType:(NSString *)type
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

- (id)initWithDataKey:(NSString *)dkey
             typeDict:(NSString *)dict
            sortField:(NSString *)sort
         editRenderer:(OTMEditDetailCellRenderer *)edit
      addMoreRenderer:(OTMUdfAddMoreRenderer *)more
{
    self = [super initWithDataKey:dkey editRenderer:nil];
    [self generateDictFromString:dict];
    [self setHeight];
    self.sortField = sort;
    self.editCellRenderer = edit;
    return self;
}

- (void)generateDictFromString:(NSString *)dictString
{
    NSArray *typesArray = [dictString copy];

    // Making the assumption that in a UDF there cannot be multiple fields with
    // the same name.
    NSMutableDictionary *typesDict = [[NSMutableDictionary alloc] init];
    for (id type in typesArray) {
        [typesDict setObject:type forKey:[type objectForKey:@"name"]];
    }
    self.typeDict = [typesDict copy];
}

- (void)setHeight
{
    CGFloat height = self.cellHeight;
    // For each row of text add 13 to the cell height to accomodate the height
    // of the line.
    height += 13 * ([self.typeDict count] - 1);
    // If we have a sort field (which is displayed on the right side of the cell
    // Drop the size to accomodate a line having been removed.
    if (self.sortField) {
        height -= 13;
    }
    self.cellHeight = height;
}

@end

@implementation OTMCellSorter

- (id)initWithCell:(UITableViewCell *)cell
           sortKey:(NSString *)key
          sortData:(NSString *)data
            height:(CGFloat)h
     clickCallback:(Function1v)callback;
{
    self = [super init];
    if (self) {
        self.cell = cell;
        self.sortKey = key;
        self.sortData = data;
        self.cellHeight = h;
        self.clickCallback = callback;
    }
    return self;
}

@end
