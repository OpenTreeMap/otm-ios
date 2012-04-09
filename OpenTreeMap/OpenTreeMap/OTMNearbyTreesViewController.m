//
//  OTMNearbyTreesViewController.m
//  OpenTreeMap
//
//  Created by Adam Hinz on 4/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OTMNearbyTreesViewController.h"
#import "OTMDistanceTableViewCell.h"

#define kOTMNearbyTreesViewControllerTableViewCellReuseIdentifier @"kOTMNearbyTreesViewControllerTableViewCellReuseIdentifier"

// in meters
#define kOTMNearbyTreesViewControllerMinimumDistance 30
#define kOTMNearbyTreesViewControllerMinimumEventDistance 5

@interface OTMNearbyTreesViewController ()

@end

@implementation OTMNearbyTreesViewController

@synthesize locationManager, tableView, nearbyTrees, lastLocation;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

//TODO: Handle unauthorized view
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.locationManager == nil) {
        CLLocationManager *manager = [[CLLocationManager alloc] init];
        manager.delegate = self;
        manager.distanceFilter = kOTMNearbyTreesViewControllerMinimumEventDistance;
        
        self.locationManager = manager;
    }
    
	// Do any additional setup after loading the view.
}
- (void)viewWillAppear:(BOOL)animated {
    [self.locationManager startUpdatingLocation];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.locationManager stopUpdatingLocation];
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

#pragma mark -
#pragma mark Table Delegate and Datasource Methods

- (UITableViewCell *)tableView:(UITableView *)tblView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    OTMDistanceTableViewCell *cell = [tblView dequeueReusableCellWithIdentifier:kOTMNearbyTreesViewControllerTableViewCellReuseIdentifier];
    
    if (cell == nil) {
        cell = [[OTMDistanceTableViewCell alloc] initWithReuseIdentifier:kOTMNearbyTreesViewControllerTableViewCellReuseIdentifier];
    
    }
    
    NSDictionary *plot = [self.nearbyTrees objectAtIndex:[indexPath row]];
    NSDictionary *geom = [plot objectForKey:@"geometry"];
    CLLocation *treeLoc = [[CLLocation alloc] initWithLatitude:[[geom valueForKey:@"lat"] doubleValue]
                                                     longitude:[[geom valueForKey:@"lng"] doubleValue]];
    
    NSDictionary *tree = [plot objectForKey:@"tree"];
    
    if (tree == nil || tree == [NSNull null]) {
        cell.textLabel.text = @"Unassigned Plot";
        cell.detailTextLabel.text = [NSString stringWithFormat:@"Plot #%@",[plot objectForKey:@"id"]];
    } else {
        cell.textLabel.text = [tree objectForKey:@"species_name"];
        if (cell.textLabel.text == nil) {
            cell.textLabel.text = @"(No Species)";
        }
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@",
                                     [tree valueForKey:@"dbh"]];
                    
    }
    cell.thisLoc = treeLoc;
    cell.curLoc = self.lastLocation;
    
    return cell;
}

- (void)tableView:(UITableView *)tblView didSelectRowAtIndexPath:(NSIndexPath *)path {

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.nearbyTrees count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(void)refreshTableWithLocation:(CLLocation *)loc {
    [[[OTMEnvironment sharedEnvironment] api] getPlotsNearLatitude:loc.coordinate.latitude
                                                         longitude:loc.coordinate.longitude
                                                        maxResults:50
                                                          callback:^(NSArray *json, NSError *error)
     {
         if (json) {
             self.nearbyTrees = [json mutableCopy];             
             [self.tableView reloadData];
         }
     }];    
}

#pragma mark -
#pragma mark Core Location Delegate

-(void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)loc fromLocation:(CLLocation *)from {
    [[NSNotificationCenter defaultCenter] postNotificationName:kOTMDistaneTableViewCellRedrawDistance
                                                        object:loc];
    if (self.lastLocation == nil || [self.lastLocation distanceFromLocation:loc] > kOTMNearbyTreesViewControllerMinimumDistance) {
        self.lastLocation = loc;
        [self refreshTableWithLocation:loc];
    }
}

@end
