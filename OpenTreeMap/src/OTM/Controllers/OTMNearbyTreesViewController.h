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

#import <UIKit/UIKit.h>
#import "OTMFilterListViewController.h"

@interface OTMNearbyTreesViewController : UIViewController<CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) CLLocationManager *locationManager;

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UISegmentedControl *segControl;
@property (nonatomic, strong) NSMutableArray *nearbyTrees;
@property (nonatomic, strong) CLLocation *lastLocation;
@property (nonatomic, strong) OTMFilters *filters;

@property (nonatomic, strong, readonly) NSMutableArray *nearby;
@property (nonatomic, strong, readonly) NSMutableArray *pending;
@property (nonatomic, strong, readonly) NSMutableArray *recent;

-(IBAction)updateList:(UISegmentedControl *)control;

@end
