//
//  OTMNearbyTreesViewController.h
//  OpenTreeMap
//
//  Created by Adam Hinz on 4/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OTMFilterListViewController.h"

@interface OTMNearbyTreesViewController : UIViewController<CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) CLLocationManager *locationManager;

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UISegmentedControl *segControl;
@property (nonatomic, strong) NSMutableArray *nearbyTrees;
@property (nonatomic, strong) CLLocation *lastLocation;
@property (nonatomic, strong) OTMFilters *filters;

@property (nonatomic, strong, readonly) NSMutableArray *nearBy;
@property (nonatomic, strong, readonly) NSMutableArray *pending;
@property (nonatomic, strong, readonly) NSMutableArray *recent;

-(IBAction)updateList:(UISegmentedControl *)control;

@end
