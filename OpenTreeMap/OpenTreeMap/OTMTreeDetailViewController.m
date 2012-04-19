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
#import "OTMDetailCellRenderer.h"

@interface OTMTreeDetailViewController ()

@end

@implementation OTMTreeDetailViewController

@synthesize data, keys, tableView, address, species, lastUpdateDate, updateUser, imageView, pictureTaker, headerView, acell;

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
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)updatePicture {
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

- (void)setKeys:(NSArray *)k {
    NSMutableArray *txToEditRm = [NSMutableArray array];
    NSMutableArray *txToEditRel = [NSMutableArray array];
    allFields = k;
    
    NSMutableArray *editableFields = [NSMutableArray array];
    
    OTMStaticClickCellRenderer *speciesRow = 
    [[OTMStaticClickCellRenderer alloc] initWithKey:@"tree.species_name"
                                      clickCallback:^(OTMDetailCellRenderer *renderer) 
    { 
        [self performSegueWithIdentifier:@"changeSpecies"
                                  sender:self];
    }];
    speciesRow.defaultName = @"Set Species";
    
    OTMDetailCellRenderer *pictureRow = 
    [[OTMStaticClickCellRenderer alloc] initWithName:@"Change Tree Picture"
                                                 key:@""
                                       clickCallback:^(OTMDetailCellRenderer *renderer) 
    { 
        [self updatePicture];
    }];    
    
    NSArray *speciesAndPicSection = [NSArray arrayWithObjects:speciesRow,pictureRow,nil];
    [editableFields addObject:speciesAndPicSection];
    
    for(int section=0;section < [allFields count];section++) {
        NSArray *sectionArray = [allFields objectAtIndex:section];
        NSMutableArray *editSectionArray = [NSMutableArray array];
        
        for(int row=0;row < [sectionArray count]; row++) {
            OTMDetailCellRenderer *renderer = [sectionArray objectAtIndex:row];
            if (renderer.editCellRenderer != nil) {
                [editSectionArray addObject:renderer.editCellRenderer];
                [txToEditRel addObject:[NSIndexPath indexPathForRow:row inSection:section]];
            } else {
                [txToEditRm addObject:[NSIndexPath indexPathForRow:row inSection:section]];
            }
        }
        
        [editableFields addObject:editSectionArray];
    }
    
    txToEditReload = txToEditRel;
    txToEditRemove = txToEditRm;
    editFields = editableFields;

    curFields = allFields;
}

- (IBAction)startEditing:(id)sender {    
    [self.activeField resignFirstResponder];
    
    // Edit mode represents the mode that we are transitioning to
    editMode = !editMode;
    
    if (editMode) { // Tx to edit mode
        curFields = editFields;
        
        [self.tableView beginUpdates];
        
        [self.tableView deleteRowsAtIndexPaths:txToEditRemove
                              withRowAnimation:UITableViewRowAnimationFade];
        
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:0]
                      withRowAnimation:UITableViewRowAnimationFade];
        
        [UIView animateWithDuration:0.3
                         animations:^{
                             self.headerView.frame =
                                CGRectOffset(self.headerView.frame,
                                             0, -self.headerView.frame.size.height);
                             
                             self.tableView.contentInset = UIEdgeInsetsZero;
                         }];
        
        [self.tableView endUpdates];
    } else { // Tx from edit mdoe
        for(NSArray *section in editFields) {
            for(OTMEditDetailCellRenderer *editFld in section) {
                self.data = [editFld updateDictWithValueFromCell:data];
            }
        }
        
        [self syncTopData];
        
        curFields = allFields;
        
        [self.tableView beginUpdates];
        
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:0]
                      withRowAnimation:UITableViewRowAnimationFade];        
        
        [self.tableView insertRowsAtIndexPaths:txToEditRemove
                              withRowAnimation:UITableViewRowAnimationFade]; 
        
        [UIView animateWithDuration:0.3
                         animations:^{
                             self.headerView.frame =
                             CGRectOffset(self.headerView.frame,
                                          0, self.headerView.frame.size.height);
                             
                             self.tableView.contentInset = 
                             UIEdgeInsetsMake(self.headerView.frame.size.height, 0, 0, 0);
                         }];        
        
        [self.tableView endUpdates];
    }
    
    // Need to reload all of the cells after animation is done
    double delayInMSeconds = 250;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInMSeconds * NSEC_PER_MSEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self.tableView reloadData];
    });
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
    return [curFields count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[curFields objectAtIndex:section] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return nil;
}

- (void)tableView:(UITableView *)tblView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    Function1v clicker = [[[curFields objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] clickCallback];
    
    if (clicker) {
        clicker(tblView);
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

- (CGFloat)tableView:(UITableView *)tblView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [[[curFields objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] cellHeight];
}

- (UITableViewCell *)tableView:(UITableView *)tblView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    OTMDetailCellRenderer *renderer = [[curFields objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    
    UITableViewCell *cell = [renderer prepareCell:self.data inTable:tblView];
    
    // Text field delegates handle proper sizing...
    // this may be a bit of a hack
    if ([cell respondsToSelector:@selector(setTfDelegate:)]) {
        [cell performSelector:@selector(setTfDelegate:) withObject:self];
    }
    
    return cell;
}

@end
