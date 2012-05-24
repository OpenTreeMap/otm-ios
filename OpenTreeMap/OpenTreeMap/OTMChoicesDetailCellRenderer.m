//
//  OTMChoicesDetailCellRenderer.m
//  OpenTreeMap
//
//  Created by Adam Hinz on 4/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OTMChoicesDetailCellRenderer.h"

#define kOTMChoicesDetailCellRendererTableCellId @"kOTMChoicesDetailCellRendererTableCellId" 

@implementation OTMChoicesDetailCellRenderer

@synthesize label, fieldName, fieldChoices;

-(id)initWithDict:(NSDictionary *)dict {
    self = [super initWithDict:dict];
    
    if (self) {
        label = [dict objectForKey:@"label"];
        fieldName = [dict objectForKey:@"fname"];
        fieldChoices = [[[OTMEnvironment sharedEnvironment] choices] objectForKey:fieldName];
        
        self.editCellRenderer = [[OTMEditChoicesDetailCellRenderer alloc] initWithDetailRenderer:self];
    }
    
    return self;
}

-(UITableViewCell *)prepareCell:(NSDictionary *)data inTable:(UITableView *)tableView {
    OTMDetailTableViewCell *detailcell = [tableView dequeueReusableCellWithIdentifier:kOTMChoicesDetailCellRendererTableCellId];
    
    if (detailcell == nil) {
        detailcell = [[OTMDetailTableViewCell alloc] initWithStyle:UITableViewCellStyleValue2
                                                   reuseIdentifier:kOTMChoicesDetailCellRendererTableCellId];
    } 
    
    NSString *value = [[data decodeKey:self.dataKey] description];
    
    NSString *output = @"(Not Set)";
    
    for(NSDictionary *choice in fieldChoices) {
        if ([value isEqualToString:[[choice objectForKey:@"key"] description]]) {
            output = [choice objectForKey:@"value"];
        }
    }
    
    detailcell.fieldLabel.text = self.label;
    detailcell.fieldValue.text = output;   
    detailcell.accessoryType = UITableViewCellAccessoryNone;
    
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
            if ([value isEqualToString:[[choice objectForKey:@"key"] description]]) {
                txt = [choice objectForKey:@"value"];
            }
        }
        
        cell.fieldValue.text = txt;
    }
    
    output = cell.fieldValue.text;
    
    return cell;
}

-(NSDictionary *)updateDictWithValueFromCell:(NSDictionary *)dict {
    if (selected) {
        [dict setObject:[selected objectForKey:@"key"] forEncodedKey:renderer.dataKey];
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
    
    cell.fieldValue.text = [selected objectForKey:@"value"];
    
    [tblView reloadData];
}

- (UITableViewCell *)tableView:(UITableView *)tblView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *selectedDict = [renderer.fieldChoices objectAtIndex:[indexPath row]];
    
    UITableViewCell *aCell = [tblView dequeueReusableCellWithIdentifier:kOTMEditChoicesDetailCellRendererCellId];
    
    if (aCell == nil) {
        aCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:kOTMEditChoicesDetailCellRendererCellId];
    }
    
    aCell.textLabel.text = [selectedDict objectForKey:@"value"];
    aCell.accessoryType = UITableViewCellAccessoryNone;
    
    if (selected != nil) {
        if ([[[selectedDict objectForKey:@"key"] description] isEqualToString:[[selected objectForKey:@"key"] description]]) {
            aCell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    } else {
        if ([[selectedDict objectForKey:@"value"] isEqualToString:output]) {
            aCell.accessoryType = UITableViewCellAccessoryCheckmark;            
        }
    }
    
    return aCell;
}
    

@end