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

#import "OTMChoicesDetailCellRenderer.h"

#define kOTMChoicesDetailCellRendererTableCellId @"kOTMChoicesDetailCellRendererTableCellId"

@implementation OTMChoicesDetailCellRenderer

@synthesize label, fieldChoices, isMulti, clickURL;

-(id)initWithDataKey:(NSString *)datakey
               label:(NSString *)labelname
            clickUrl:(NSString *)clickurl
             choices:(NSArray *)choices
             isMulti:(BOOL)ismulti
            writable:(BOOL)writable {

    self = [super initWithDataKey:datakey];

    if (self) {
        self.label = labelname;
        self.clickURL = clickurl;
        self.isMulti = ismulti;
        self.fieldChoices = choices;

        if (writable) {
            self.editCellRenderer = [[OTMEditChoicesDetailCellRenderer alloc] initWithDetailRenderer:self];
        }
    }

    return self;
}

-(void)showLink:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.clickURL]];
}

#define OTMChoicesDetailCellRenndererShowUrlLinkButtonView 19191

- (NSString *)stringForValue:(NSObject *)value {
    if (self.isMulti) {
        return [(NSArray *)value componentsJoinedByString:@", "];
    } else {
        return [value description];
    }
}

- (OTMCellSorter *)prepareCell:(NSDictionary *)data inTable:(UITableView *)tableView
{
    OTMDetailTableViewCell *detailcell = [tableView dequeueReusableCellWithIdentifier:kOTMChoicesDetailCellRendererTableCellId];

    if (detailcell == nil) {
        detailcell = [[OTMDetailTableViewCell alloc] initWithStyle:UITableViewCellStyleValue2
                                                   reuseIdentifier:kOTMChoicesDetailCellRendererTableCellId];
    }

    NSString *value = [self stringForValue:[data decodeKey:self.dataKey]];

    NSDictionary *pendingEditDict = [data objectForKey:@"pending_edits"];
    if (pendingEditDict) {
        if ([pendingEditDict objectForKey:self.dataKey]) {
            detailcell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            value = [self stringForValue:[[pendingEditDict objectForKey:self.dataKey] objectForKey:@"latest_value"]];
        } else {
            detailcell.accessoryType = UITableViewCellAccessoryNone;
        }
    }

    detailcell.fieldLabel.text = self.label;
    detailcell.fieldValue.text = value;

    [[detailcell viewWithTag:OTMChoicesDetailCellRenndererShowUrlLinkButtonView] removeFromSuperview];

    if (self.clickURL) {
        UIButton *link = [UIButton buttonWithType:UIButtonTypeInfoDark];
        link.tag = OTMChoicesDetailCellRenndererShowUrlLinkButtonView;
        [link addTarget:self action:@selector(showLink:) forControlEvents:UIControlEventTouchUpInside];
        CGSize titleSize = [self.label sizeWithFont:detailcell.fieldLabel.font];
        link.frame = CGRectOffset(link.frame, 38 + titleSize.width, 13);

        [detailcell addSubview:link];
    }

    return [[OTMCellSorter alloc] initWithCell:detailcell
                                       sortKey:nil
                                      sortData:nil
                                        height:self.cellHeight
                                 clickCallback:nil];
}
@end

#define kOTMEditChoicesDetailCellRendererCellId @"kOTMEditChoicesDetailCellRendererCellId"

@implementation OTMEditChoicesDetailCellRenderer

@synthesize renderer, controller, selectedValues, cell;

-(id)initWithDetailRenderer:(OTMChoicesDetailCellRenderer *)ocdcr {
    self = [super init];

    if (self) {
        renderer = ocdcr;
        selectedValues = [[NSMutableSet alloc] init];
        controller = [[UITableViewController alloc] init];
        controller.navigationItem.hidesBackButton = YES;
        controller.navigationItem.rightBarButtonItem =
          [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                        target:self
                                                        action:@selector(done:)];

        __block UIViewController *tableController = controller;
        self.clickCallback = ^(UIViewController *aController,  NSMutableDictionary *dict) {
            [aController.navigationController pushViewController:tableController animated:YES];
        };

        controller.tableView.delegate = (id<UITableViewDelegate>)self;
        controller.tableView.dataSource = (id<UITableViewDataSource>)self;
    }

    return self;
}

- (NSString *)stringForValue:(NSObject *)value {
    if (self.renderer.isMulti) {
        return [(NSArray *)value componentsJoinedByString:@", "];
    } else {
        return [value description];
    }
}

- (NSMutableSet *)setForValue:(NSObject *)value {
    if (self.renderer.isMulti) {
        return [[NSMutableSet alloc] initWithArray:(NSArray *)value];
    } else {
        return [[NSMutableSet alloc] initWithObjects:value, nil];
    }
}

-(void)done:(id)sender {
    [controller.navigationController popViewControllerAnimated:YES];
}

- (OTMCellSorter *)prepareCell:(NSDictionary *)renderData inTable:(UITableView *)tableView
{

    if (!cell) {
        cell = [[OTMDetailTableViewCell alloc] initWithStyle:UITableViewCellStyleValue2
                                                   reuseIdentifier:kOTMEditChoicesDetailCellRendererCellId];
    }

    cell.fieldLabel.text = renderer.label;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    NSObject *dataValue = [renderData decodeKey:renderer.dataKey];
    selectedValues = [self setForValue:dataValue];
    [controller.tableView reloadData];

    if ([selectedValues count] > 0) {
        cell.fieldValue.text = [[selectedValues allObjects] componentsJoinedByString:@", "];
    } else {
        cell.fieldValue.text = @"";
    }

    return [[OTMCellSorter alloc] initWithCell:cell
                                       sortKey:nil
                                      sortData:nil
                                        height:self.cellHeight
                                 clickCallback:self.clickCallback];
}

-(NSDictionary *)updateDictWithValueFromCell:(NSDictionary *)dict {
    NSObject *value;
    if (self.renderer.isMulti) {
        value = [selectedValues allObjects];
    } else {
        if ([selectedValues count] > 0) {
            value = [[selectedValues allObjects] objectAtIndex:0];
        } else {
            value = @"";
        }
    }
    [dict setObject:value forEncodedKey:renderer.dataKey];
    return dict;
}

#pragma mark -
#pragma mark Choices View Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [renderer.fieldChoices count];
}

- (void)tableView:(UITableView *)tblView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *tappedValue = [[renderer.fieldChoices objectAtIndex:[indexPath row]] objectForKey:@"value"];
    if (self.renderer.isMulti) {
        if ([self.selectedValues member:tappedValue]) {
            [selectedValues removeObject:tappedValue];
        } else {
            [selectedValues addObject:tappedValue];
        }
    } else {
        selectedValues = [[NSMutableSet alloc] initWithObjects:tappedValue, nil];
    }


    cell.fieldValue.text = [[selectedValues allObjects] componentsJoinedByString:@", "];

    [tblView reloadData];
}

- (UITableViewCell *)tableView:(UITableView *)tblView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *selectedDict = [renderer.fieldChoices objectAtIndex:[indexPath row]];

    UITableViewCell *aCell = [tblView dequeueReusableCellWithIdentifier:kOTMEditChoicesDetailCellRendererCellId];

    if (aCell == nil) {
        aCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:kOTMEditChoicesDetailCellRendererCellId];
    }

    aCell.textLabel.text = [selectedDict objectForKey:@"display_value"];
    aCell.accessoryType = UITableViewCellAccessoryNone;

    if ([selectedValues member:[selectedDict objectForKey:@"value"]]) {
        aCell.accessoryType = UITableViewCellAccessoryCheckmark;
    }

    return aCell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (self.renderer.isMulti) {
        return @"Select any number of items";
    } else {
        return @"Select one item";
    }
}

@end
