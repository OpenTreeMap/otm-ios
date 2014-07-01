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

#import "OTMAllInstancesTableViewController.h"
#import "OTMPreferences.h"
#import "OTMInstanceSelectTableViewController.h"


@interface OTMAllInstancesTableViewController ()

@end

@implementation OTMAllInstancesTableViewController

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

    [[[OTMEnvironment sharedEnvironment] api] getAllPublicInstancesWithCallback:^(id json, NSError *err)
    {
         if (err) {
             [[[UIAlertView alloc] initWithTitle:@"Error"
                                         message:@"Could not load map list"
                                        delegate:nil
                               cancelButtonTitle:@"OK"
                               otherButtonTitles:nil] show];
             [self.navigationController popViewControllerAnimated:YES];
             NSLog(@"Failed to load data from instance endpoint. %@", [err description]);
         } else {
             _instances = json;
             [self loadSectionDictWithSearchText:nil];
             [self.tableView reloadData];
         }
     }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadSectionDictWithSearchText:(NSString *)searchText {
    _filteredInstances = [[NSMutableArray alloc] init];
    for (NSString *displayValue in [_instances allKeys]) {
        if (displayValue != (id)[NSNull null] && [displayValue length] > 0 && [self instanceName:displayValue matchesSearchText:searchText]) {
            [_filteredInstances addObject:displayValue];
        }
    }
}

- (BOOL)instanceName:(NSString *)name matchesSearchText:(NSString *)searchText {
    NSString *lowerSearchText = [searchText lowercaseString];
    if (!lowerSearchText || lowerSearchText.length == 0) {
        return YES; // nil empty search text matches anything
    } else if ([[name lowercaseString] rangeOfString:lowerSearchText].location != NSNotFound) {
        return YES; // if the search text is a substring of the name it is a match.
    } else {
        return NO;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([_instances count] == 0) {
        return 1;
    } else {
        return [_filteredInstances count];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Tree Maps";
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"instanceCell" forIndexPath:indexPath];
    if (_instances == nil) {
        cell.textLabel.text = @"Loading maps...";
    } else {
        NSArray *sortedNames = [_filteredInstances sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [obj1 caseInsensitiveCompare:obj2];
        }];
        cell.textLabel.text = [sortedNames objectAtIndex:indexPath.row];
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    NSString *url = [_instances objectForKey:cell.textLabel.text];
    if (url) {
        [self.delegate instanceDidUpdate:self withInstanceUrl:url];
    } else {
        NSLog(@"No url property in %@", _instances);
    }
}

- (void)searchBar:(UISearchBar *)search textDidChange:(NSString *)searchText
{
    [self loadSectionDictWithSearchText:searchText];
    [self.tableView reloadData];
}

@end