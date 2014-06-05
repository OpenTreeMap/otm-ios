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

#import "OTMSpeciesTableViewController.h"
#import "OTMDetailTableViewCell.h"

@interface OTMSpeciesTableViewController ()

@end

@implementation OTMSpeciesTableViewController

@synthesize tableView, callback, searchBar;

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

    sections =  [NSArray arrayWithObjects:@"A",@"B",@"C",@"D",@"E",@"F",@"G",@"H",@"I",@"J",@"K",@"L",@"M",@"N",@"O",
                    @"P",@"Q",@"R",@"S",@"T",@"U",@"V",@"W",@"X",@"Y",@"Z", nil];

    OTMLoginManager* loginManager = [SharedAppDelegate loginManager];
    [[[OTMEnvironment sharedEnvironment] api] getSpeciesListForUser:loginManager.loggedInUser
                                                       withCallback:^(id json, NSError *err)
     {
         if (err) {
             [[[UIAlertView alloc] initWithTitle:@"Error"
                                         message:@"Could not load species list"
                                        delegate:nil
                               cancelButtonTitle:@"OK"
                               otherButtonTitles:nil] show];
             [self.navigationController popViewControllerAnimated:YES];
         } else {
             species = json;
             [self loadSectionDictWithSearchText:nil];
             [self.tableView reloadData];
         }
     }];
}

- (BOOL)speciesWithCommonName:(NSString *)name matchesSearchText:(NSString *)searchText {
    NSString *lowerSearchText = [searchText lowercaseString];
    if (!lowerSearchText || lowerSearchText.length == 0) {
        return YES; // nil empty search text matches anything
    } else if ([[name lowercaseString] rangeOfString:lowerSearchText].location != NSNotFound) {
        return YES; // if the search text is a substring of the common name it is a match
    } else {
        NSString *lowerSciName = [[[species objectForKey:name] objectForKey:@"scientific_name"] lowercaseString];
        // if the search text is a substring of the scientific name it is a match
        return ([lowerSciName rangeOfString:lowerSearchText].location != NSNotFound);
    }
}

- (void)loadSectionDictWithSearchText:(NSString *)searchText {
    sectionDict = [NSMutableDictionary dictionary];
    for(NSString *displayValue in [species allKeys]) {
        if (displayValue != (id)[NSNull null] && [displayValue length] > 0 && [self speciesWithCommonName:displayValue matchesSearchText:searchText]) {
            NSString *key = [[displayValue substringToIndex:1] uppercaseString];
            NSMutableArray *vals = [sectionDict objectForKey:key];
            if (vals == nil) {
                vals = [NSMutableArray array];
                [sectionDict setObject:vals forKey:key];
            }
            [vals addObject:displayValue];
        }
    }
    for(NSString *s in sections) {
        NSArray *vals = [sectionDict objectForKey:s];
        if (vals) {
            [sectionDict setObject:[vals sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]
                            forKey:s];
        }
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return sections;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return MAX(1, [sections count]);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([species count] == 0 && section == 0) {
        return 1; // show the loading row
    } else {
        return [[sectionDict objectForKey:[sections objectAtIndex:section]] count];
    }
}

#define kSpeciesListCellReuseIdentifier @"kSpeciesListCellReuseIdentifier"

- (UITableViewCell *)tableView:(UITableView *)tblView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tblView dequeueReusableCellWithIdentifier:kSpeciesListCellReuseIdentifier];

    if (species == nil) {
        cell.textLabel.text = @"Loading Species...";
    } else {
        cell.textLabel.text = [[sectionDict objectForKey:[sections objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
        cell.detailTextLabel.text = [[species objectForKey:cell.textLabel.text] objectForKey:@"scientific_name"];
    }

    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [sections objectAtIndex:section];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (callback) {
        id key = [[sectionDict objectForKey:[sections objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
        NSDictionary *speciesDetailDict = [species objectForKey:key];
        callback(speciesDetailDict);
    }
    OTMDetailTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    [self.delegate speciesDetailsViewControllerDidUpdate:self withNewSpecies:cell.textLabel.text];
}

#pragma mark - UISearchBar delegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self loadSectionDictWithSearchText:searchText];
    [self.tableView reloadData];
}

@end
