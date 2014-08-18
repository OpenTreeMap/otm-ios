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

#import "OTMInstanceSelectTableViewController.h"
#import "OTMPreferences.h"
#import "OTMAllInstancesTableViewController.h"

@interface OTMInstanceSelectTableViewController ()

@end

@implementation OTMInstanceSelectTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;

    // Uncomment the following line to display an Edit button in the navigation
    // bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    // The call to getInstancesNearLatitude uses 320000m as the radius.
    // This is about 200 miles, which is greater than Seattle -> Portland,
    // Philly -> Washington DC. It seemed reasonable when we picked it, but
    // is arbitrary.
    [[OTMPreferences sharedPreferences] setInstance:@""];
    [[[OTMEnvironment sharedEnvironment] api] resetSpeciesList];

    OTMLoginManager* loginManager = [SharedAppDelegate loginManager];
    if ([[loginManager loggedInUser] loggedIn]) {
        [[self logInOutButton] setTitle:@"Switch Accounts" forState:UIControlStateNormal];
    } else {
        [[self logInOutButton] setTitle:@"Login to OpenTreeMap" forState:UIControlStateNormal];
    }

    if (![self locationManager]) {
        [self setLocationManager:[[OTMLocationManager alloc] initWithDistanceRestriction:NO]];
    }

    // TODO: Maybe show loading indicator
    [[self locationManager] findLocation:^(CLLocation *location, NSError *error) {
        // TODO: if there is an error, we need to show some list of instances
        if (!error) {
            [[[OTMEnvironment sharedEnvironment] api]
             getInstancesNearLatitude:location.coordinate.latitude
                            longitude:location.coordinate.longitude
                                user:[[SharedAppDelegate loginManager] loggedInUser]
                          maxResults:5
                             distance:320000 callback:^(id json, NSError *error) {
                                 if (!error) {
                                     NSLog(@"Retrieved instances: %@", json);
                                     [self updateInstancesFromDictionary:json];
                                 } else {
                                     NSLog(@"Error getting nearby instances: %@", error);
                                 }
            }];
        } else {
            NSLog(@"Error finding location: %@", error);
            if ([[[SharedAppDelegate loginManager] loggedInUser] loggedIn]) {
                [[[OTMEnvironment sharedEnvironment] api]
                 getInstancesNearLatitude:0
                                longitude:0
                                     user:[[SharedAppDelegate loginManager] loggedInUser]
                               maxResults:5
                                 distance:0 callback:^(id json, NSError *error) {
                                     if (!error) {
                                         [self updateInstancesFromDictionary:json];
                                     } else {
                                         NSLog(@"Error getting for: %@", error);
                                     }
                                 }];
            }
        }
    }];
}

- (void)updateInstancesFromDictionary:(NSDictionary *)instances
{
    [self setInstances:instances];
    [[self tableView] reloadData];
}

- (BOOL)hasNearbyInstances
{
    return [self nearbyInstanceCount] > 0;
}

- (int)nearbyInstanceCount
{
    if ([[self instances] objectForKey:@"nearby"]) {
        return [[[self instances] objectForKey:@"nearby"] count];
    } else {
        return 0;
    }
}

- (BOOL)hasPersonalInstances
{
    return [self personalInstanceCount] > 0;
}

- (int)personalInstanceCount
{
    if ([[self instances] objectForKey:@"personal"]) {
        return [[[self instances] objectForKey:@"personal"] count];
    } else {
        return 0;
    }
}

- (void)loadDetailAndSegueToMapViewForInstanceWithUrlName:(NSString *)urlName {
    AZUser* user = [[SharedAppDelegate loginManager] loggedInUser];

    OTM2API *api = [[OTMEnvironment sharedEnvironment] api2];
    [api loadInstanceInfo:urlName
                  forUser:user
             withCallback:^(id json, NSError *error) {

                 if (error != nil) {
                     [UIAlertView showAlertWithTitle:nil
                                             message:@"There was a problem connecting to the server. Hit OK to try again."
                                   cancelButtonTitle:@"OK"
                                    otherButtonTitle:nil
                                            callback:^(UIAlertView *alertView, int btnIdx)
                      {
                          NSLog(@"Failed to load instance data for %@ -- error message follows: %@", urlName, [error description]) ;
                      }];
                     // If we fail for some reason, kick back to the original
                     // value from the plist. This should really only happen for
                     // the cloud app but if for some reason we happen to fail
                     // for one of the other apps, we don't want to hard code
                     // the empty string that represents cloud and accidentaly
                     // turn a branded app into a cloud app. This ought to save
                     // us from expired instances.
                     NSBundle* bundle = [NSBundle mainBundle];

                     NSString* implementationPListPath =
                        [bundle pathForResource:@"Implementation" ofType:@"plist"];

                     NSDictionary* implementation =
                        [[NSDictionary alloc] initWithContentsOfFile: implementationPListPath];

                     NSString *instance = [implementation objectForKey:@"instance"];
                     [[OTMEnvironment sharedEnvironment] setInstance:instance];
                 } else {
                     [[OTMEnvironment sharedEnvironment] updateEnvironmentWithDictionary:json];
                     [self performSegueWithIdentifier:@"showInstance" sender:self];
                 }
             }];
}

- (IBAction)logInOut:(id)sender;
{
    if ([[[SharedAppDelegate loginManager] loggedInUser] loggedIn]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kOTMLoginWorkflowLogout
                                                            object:self
                                                          userInfo:nil];
    }
    OTMLoginManager* loginManager = [SharedAppDelegate loginManager];

    [loginManager presentModelLoginInViewController:self.parentViewController callback:^(BOOL success, OTMUser *aUser) {
        if (success) {
            loginManager.loggedInUser = aUser;
            [[self tableView] reloadData];
        }
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    int sectionCount = 0;
    if ([self hasNearbyInstances]) {
        sectionCount += 1;
    }
    if ([self hasPersonalInstances]) {
        sectionCount += 1;
    }
    // Add one for the "All maps section"
    sectionCount += 1;
    return sectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([self hasPersonalInstances] && [self hasNearbyInstances]) {
        if (section == 0) {
            return [self personalInstanceCount];
        } else if (section == 1) {
            return [self nearbyInstanceCount];
        } else {
            return 1;
        }
    } else if ([self hasPersonalInstances]) {
        if (section == 0) {
            return [self personalInstanceCount];
        } else {
            return 1;
        }
    } else if ([self hasNearbyInstances]) {
        if (section == 0) {
            return [self nearbyInstanceCount];
        } else {
            return 1;
        }
    } else {
        return 1;
    }
}


- (NSDictionary *)instanceDictFromInstancePath:(NSIndexPath *)indexPath
{
    NSDictionary *instanceDict;
    if ([self hasPersonalInstances]) {
        if (indexPath.section == 0) {
            instanceDict = [[[self instances] objectForKey:@"personal"] objectAtIndex:indexPath.row];
        } else { // indexPath.section == 1
            instanceDict = [[[self instances] objectForKey:@"nearby"] objectAtIndex:indexPath.row];
        }
    } else {
        instanceDict = [[[self instances] objectForKey:@"nearby"] objectAtIndex:indexPath.row];
    }
    return instanceDict;
}


- (NSString *)instanceNameFromIndexPath:(NSIndexPath *)indexPath
{
    return [self instanceNameFromDictionary:[self instanceDictFromInstancePath:indexPath]];
}

- (NSString *)instanceNameFromDictionary:(NSDictionary *)dict
{
    NSString *name = [dict objectForKey:@"name"];
    if (name) {
        return name;
    } else {
        return @"No Name";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    if ([indexPath section] == [tableView numberOfSections] - 1) {
        static NSString *AllInstances = @"AllInstances";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:AllInstances];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:AllInstances];
        }
        [cell.textLabel setText: @"Search All Tree Maps"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        return cell;
    }

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"OTMInstanceSelectTableViewCellIdentifier" forIndexPath:indexPath];

    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"OTMInstanceSelectTableViewCellIdentifier"];
    }

    [[cell textLabel] setText:[self instanceNameFromIndexPath:indexPath]];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath section] == [tableView numberOfSections] - 1) {
        [self performSegueWithIdentifier:@"allInstances" sender: self];
    } else {
        NSDictionary *instanceDict = [self instanceDictFromInstancePath:indexPath];
        NSString *urlName = [instanceDict objectForKey:@"url"];

        if (urlName) {
            [[OTMPreferences sharedPreferences] setInstance:urlName];
            [self loadDetailAndSegueToMapViewForInstanceWithUrlName:urlName];
        } else {
            NSLog(@"No url_name property in %@", instanceDict);
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *myMaps = @"My Tree Maps";
    NSString *nearMaps = @"Nearby Tree Maps";
    NSString *otherMaps = @"Other Treemaps";
    if ([self hasPersonalInstances] && [self hasNearbyInstances]) {
        if (section == 0) {
            return myMaps;
        } else if (section == 1) {
            return nearMaps;
        } else {
            return otherMaps;
        }
    } else if ([self hasPersonalInstances]) {
        if (section == 0) {
            return myMaps;
        } else {
            return otherMaps;
        }
    } else if ([self hasNearbyInstances]) {
        if (section == 0) {
            return nearMaps;
        } else {
            return otherMaps;
        }
    } else {
        return otherMaps;
    }
}

- (void)instanceDidUpdate:(OTMAllInstancesTableViewController *)controller
          withInstanceUrl:(NSString *)instance
{
    [self.navigationController popViewControllerAnimated:YES];
    [[OTMPreferences sharedPreferences] setInstance:instance];
    [self loadDetailAndSegueToMapViewForInstanceWithUrlName:instance];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"allInstances"]) {
        OTMAllInstancesTableViewController *allInstanceTableViewController = segue.destinationViewController;
        allInstanceTableViewController.delegate = self;
    }
}


@end
