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

- (NSArray *)prepareAllCells:(NSDictionary *)data inTable:(UITableView *)tableView
{
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
                                        height:self.cellHeight];
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
                                        height:self.cellHeight];
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
            [dateFormatter setDateFormat:@"YYYY-MM-dd"];
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
                                        height:self.cellHeight];
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
                                        height:self.cellHeight];
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
                                        height:self.cellHeight];
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

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UDFCell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UDFCell"];
    }


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


    [typeTextLabel setText:self.type];
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

    return [[OTMCellSorter alloc] initWithCell:cell sortKey:self.sortField sortData:sortData height:totalHeight];
}

- (NSString *)stringifyData:(id)data byType:(NSString *)type
{
    NSString *result;
    if ([type isEqualToString:@"date"]) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"YYYY'-'MM'-'dd' 'HH':'mm':'ss'"];
        NSDate *date =[dateFormatter dateFromString:data];
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

- (id)initWithDataKey:(NSString *)dkey
             typeDict:(NSString *)dict
            sortField:(NSString *)sort
{
    self = [super initWithDataKey:dkey editRenderer:nil];
    [self generateDictFromString:dict];
    [self setHeight];
    self.sortField = sort;
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
{
    self = [super init];
    if (self) {
        self.cell = cell;
        self.sortKey = key;
        self.sortData = data;
        self.cellHeight = h;
    }
    return self;
}

@end
