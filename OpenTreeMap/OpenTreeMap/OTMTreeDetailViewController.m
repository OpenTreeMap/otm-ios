//
// Copyright (c) 2012 Azavea
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//  

#import "OTMTreeDetailViewController.h"
#import "OTMDetailTableViewCell.h"
#import "OTMSpeciesTableViewController.h"
#import "OTMFormatters.h"
#import "OTMMapViewController.h"

@interface OTMTreeDetailViewController ()

@end

@implementation OTMTreeDetailViewController

@synthesize data, keys, tableView, address, species, lastUpdateDate, updateUser, imageView, pictureTaker;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated {
    // Set some fields
    [self syncTopData];
    
    [self.tableView reloadData];
}

-(void)syncTopData {
    if (self.data) {
        self.address.text = [self.data objectForKey:@"address"];
        self.species.text = [self.data decodeKey:@"tree.species_name"];
        self.lastUpdateDate.text = @"Today";
        self.updateUser.text = @"Joe User";
    }    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (pictureTaker == nil) {
        pictureTaker = [[OTMPictureTaker alloc] init];
    }
    
    [self.tableView setAllowsMultipleSelectionDuringEditing:YES];
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

- (IBAction)startEditing:(id)sender {
    [self.activeField resignFirstResponder];
    
    if (updated) {
        
    }
    
    updated = NO;
    editMode = !editMode;
    [self.tableView reloadData];
    self.tableView.editing = editMode;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    OTMSpeciesTableViewController *sVC = (OTMSpeciesTableViewController *)segue.destinationViewController;
    
    sVC.callback = ^(NSNumber *sId, NSString *name) {
        [self.data setObject:sId forEncodedKey:@"tree.species"];
        [self.data setObject:name forEncodedKey:@"tree.species_name"];   
        [self syncTopData];
    };
}

#pragma mark -
#pragma mark UITableViewDelegate/DataSource methods

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)path {
    return UITableViewCellEditingStyleNone;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [keys count] + editMode;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (editMode && section == 0) {
        return 2;
    } else {
        return MAX([[keys objectAtIndex:section - editMode] count] - 1,0);
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (editMode && section == 0) {
        return @"Species and Location";
    } else {
        return [[keys objectAtIndex:section - editMode] objectAtIndex:0];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editMode && indexPath.section == 0) {
        if (indexPath.row == 0) {
            [self performSegueWithIdentifier:@"changeSpecies"
                                      sender:self];
        } else {
            [pictureTaker getPictureInViewController:self
                                            callback:^(UIImage *image)
             {
                 self.imageView.image = image;
                 [[[OTMEnvironment sharedEnvironment] api] setPhoto:image
                                                       onPlotWithID:[[self.data objectForKey:@"id"] intValue]
                                                           withUser:nil 
                                                           callback:^(id json, NSError *err)
                  {
                      if (err == nil) {
                          [[NSNotificationCenter defaultCenter] postNotificationName:kOTMMapViewControllerImageUpdate
                                                                              object:image];
                      }
                  }];
             }];
        }
    }
}

- (void)tableViewCell:(UITableViewCell *)tblViewCell updatedToValue:(NSString *)value {
    NSIndexPath *path = [self.tableView indexPathForCell:tblViewCell];
    int section = [path section];
    int row = [path row];
    
    if (editMode) {
        if (section == 0) { return; }
        section -= 1;
    }
    
    NSMutableDictionary* cellinfo = [[self.keys objectAtIndex:section] objectAtIndex:row+1];
    
    [data setObject:value forEncodedKey:[cellinfo objectForKey:@"key"]];
    
    
}

- (UITableViewCell *)tableView:(UITableView *)tblView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString* cellId = @"genericKVCell";

    int section = [indexPath section];
    
    if (editMode && section == 0) {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                                       reuseIdentifier:@"buttoncell"];
        cell.textLabel.text = indexPath.row == 0 ? @"Set Species" : @"Take Picture";
        return cell;
    } else {
        if (editMode) {
            section -= 1;
        }
        
        OTMDetailTableViewCell* cell;
        if ((cell = [tblView dequeueReusableCellWithIdentifier:cellId]) == nil) {
            cell = [[OTMDetailTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                          reuseIdentifier:cellId];
            cell.tfDelegate = self;
            cell.delegate = self;
        }
        
        NSDictionary* cellinfo = [[self.keys objectAtIndex:section] objectAtIndex:indexPath.row+1];
        
        id rawValue = [self.data decodeKey:[cellinfo valueForKey:@"key"]];
        id value;
        
        NSString* formatKey = [cellinfo valueForKey:@"format"];
        
        if (rawValue == nil ) {
            rawValue = @"";
            value = @"";
        } else if (formatKey != nil) {
            value = [OTMFormatters fmtObject:rawValue withKey:formatKey];
        } else {
            value = [NSString stringWithFormat:@"%@",rawValue];
        }
        
        cell.fieldValue.text = value;
        cell.fieldLabel.text = [cellinfo valueForKey:@"label"];
        cell.editFieldValue.text = [NSString stringWithFormat:@"%@",rawValue];
        cell.formatKey = formatKey;
        cell.allowsEditing = [[cellinfo valueForKey:@"editable"] boolValue];
            
        return cell;
    }
}

@end
