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

@synthesize label, fieldChoices, clickURL;

-(id)initWithDataKey:(NSString *)datakey
               label:(NSString *)labelname
            clickUrl:(NSString *)clickurl
             choices:(NSArray *)choices
            writable:(BOOL)writable {

    self = [super initWithDataKey:datakey];

    if (self) {
        self.label = labelname;
        self.clickURL = clickurl;

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

-(UITableViewCell *)prepareCell:(NSDictionary *)data inTable:(UITableView *)tableView {
    OTMDetailTableViewCell *detailcell = [tableView dequeueReusableCellWithIdentifier:kOTMChoicesDetailCellRendererTableCellId];

    if (detailcell == nil) {
        detailcell = [[OTMDetailTableViewCell alloc] initWithStyle:UITableViewCellStyleValue2
                                                   reuseIdentifier:kOTMChoicesDetailCellRendererTableCellId];
    }

    NSString *value = [[data decodeKey:self.dataKey] description];

    NSString *output = @"(Not Set)";

    NSDictionary *pendingEditDict = [data objectForKey:@"pending_edits"];
    if (pendingEditDict) {
        if ([pendingEditDict objectForKey:self.dataKey]) {
            detailcell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            value = [[pendingEditDict objectForKey:self.dataKey] objectForKey:@"latest_value"];
        } else {
            detailcell.accessoryType = UITableViewCellAccessoryNone;
        }
    }

    for(NSDictionary *choice in fieldChoices) {
        if ([value isEqualToString:[[choice objectForKey:@"value"] description]]) {
            output = [choice objectForKey:@"display_value"];
        }
    }

    detailcell.fieldLabel.text = self.label;
    detailcell.fieldValue.text = output;

    [[detailcell viewWithTag:OTMChoicesDetailCellRenndererShowUrlLinkButtonView] removeFromSuperview];

    if (self.clickURL) {
        UIButton *link = [UIButton buttonWithType:UIButtonTypeInfoDark];
        link.tag = OTMChoicesDetailCellRenndererShowUrlLinkButtonView;
        [link addTarget:self action:@selector(showLink:) forControlEvents:UIControlEventTouchUpInside];
        CGSize titleSize = [self.label sizeWithFont:detailcell.fieldLabel.font];
        link.frame = CGRectOffset(link.frame, 38 + titleSize.width, 13);

        [detailcell addSubview:link];
    }

    return detailcell;
}
@end

#define kOTMEditChoicesDetailCellRendererCellId @"kOTMEditChoicesDetailCellRendererCellId"

@implementation OTMEditChoicesDetailCellRenderer

@synthesize renderer, controller, selected, output, cell;

-(id)initWithDetailRenderer:(OTMChoicesDetailCellRenderer *)ocdcr {
    self = [super init];

    if (self) {
        renderer = ocdcr;
        controller = [[UITableViewController alloc] init];
        controller.navigationItem.hidesBackButton = YES;
        controller.navigationItem.rightBarButtonItem =
          [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                        target:self
                                                        action:@selector(done:)];

        __block UIViewController *tableController = controller;
        self.clickCallback = ^(UIViewController *aController) {
            [aController.navigationController pushViewController:tableController animated:YES];
        };

        controller.tableView.delegate = (id<UITableViewDelegate>)self;
        controller.tableView.dataSource = (id<UITableViewDataSource>)self;
    }

    return self;
}

-(void)done:(id)sender {
    [controller.navigationController popViewControllerAnimated:YES];
}

-(UITableViewCell *)prepareCell:(NSDictionary *)renderData inTable:(UITableView *)tableView {

    if (cell == nil) {
        cell = [[OTMDetailTableViewCell alloc] initWithStyle:UITableViewCellStyleValue2
                                                   reuseIdentifier:kOTMEditChoicesDetailCellRendererCellId];
    }

    cell.fieldLabel.text = renderer.label;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    if (selected) {
        cell.fieldValue.text = [selected objectForKey:@"value"];
    } else {
        NSString *txt = nil;
        NSString *value = [[renderData decodeKey:renderer.dataKey] description];

        for(NSDictionary *choice in renderer.fieldChoices) {
            if ([value isEqualToString:[[choice objectForKey:@"value"] description]]) {
                txt = [choice objectForKey:@"display_value"];
            }
        }

        cell.fieldValue.text = txt;
    }

    output = cell.fieldValue.text;

    return cell;
}

-(NSDictionary *)updateDictWithValueFromCell:(NSDictionary *)dict {
    if (selected) {
        [dict setObject:[selected objectForKey:@"value"] forEncodedKey:renderer.dataKey];
    }

    selected = nil;

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
    selected = [renderer.fieldChoices objectAtIndex:[indexPath row]];

    cell.fieldValue.text = [selected objectForKey:@"display_value"];

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

    if (selected != nil) {
        if ([[[selectedDict objectForKey:@"value"] description] isEqualToString:[[selected objectForKey:@"key"] description]]) {
            aCell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    } else {
        if ([[selectedDict objectForKey:@"display_value"] isEqualToString:output]) {
            aCell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    }

    return aCell;
}


@end
