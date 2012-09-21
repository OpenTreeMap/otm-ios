//
//  OTMSpeciesTableViewController.m
//  OpenTreeMap
//
//  Created by Adam Hinz on 4/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OTMSpeciesTableViewController.h"

@interface OTMSpeciesTableViewController ()

@end

@implementation OTMSpeciesTableViewController

@synthesize tableView, callback;

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
    sectionDict = [NSMutableDictionary dictionary];

    [[[OTMEnvironment sharedEnvironment] api] getSpeciesListWithCallback:^(id json, NSError *err) 
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

             for(NSString *displayValue in [species allKeys]) {
                 if (displayValue != (id)[NSNull null] && [displayValue length] > 0) {
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
             [self.tableView reloadData];
         }
     }];
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
        callback([speciesDetailDict objectForKey:@"id"], key, [speciesDetailDict objectForKey:@"scientific_name"]);
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

@end
