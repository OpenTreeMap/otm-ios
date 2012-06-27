//
//  OTMSpeciesTableViewController.h
//  OpenTreeMap
//
//  Created by Adam Hinz on 4/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OTMSpeciesTableViewController : UITableViewController {
    NSDictionary *species;
    NSArray *sections;
    NSMutableDictionary *sectionDict;
}

@property (nonatomic,strong) Function3v callback;
@property (nonatomic,strong) IBOutlet UITableView *tableView;

@end
