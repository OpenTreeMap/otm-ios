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
#import "AZWaitingOverlayController.h"
#import "OTMChangeLocationViewController.h"
#import "OTMTreeDictionaryHelper.h"
#import "OTMFieldDetailViewController.h"

@interface OTMTreeDetailViewController ()

@end

@implementation OTMTreeDetailViewController

@synthesize data, keys, tableView, address, species, lastUpdateDate, updateUser, imageView, pictureTaker, headerView, acell, delegate, originalLocation;

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
}

-(void)syncTopData {
    if (self.data) {
        self.address.text = [self.data objectForKey:@"address"];
        if (!self.address.text || [self.address.text isEqualToString:@""]) {
            self.address.text = @"No Address";
        }

        NSDictionary *pendingSpeciesEditDict = [[self.data objectForKey:@"pending_edits"] objectForKey:@"tree.species"];
        if (pendingSpeciesEditDict) {
            NSDictionary *latestEdit = [[pendingSpeciesEditDict objectForKey:@"pending_edits"] objectAtIndex:0];
            self.species.text = [[latestEdit objectForKey:@"related_fields"] objectForKey:@"tree.species_name"];
        } else {
            if ([self.data decodeKey:@"tree.species_name"]) {
                self.species.text = [self.data decodeKey:@"tree.species_name"];
            } else {
                self.species.text = @"Missing Species";
            }
        }

        NSString *upd_on = [self reformatLastUpdateDate:[self.data objectForKey:@"last_updated"]];

        if (upd_on == nil) {
            upd_on = @"just now";
        }

        self.lastUpdateDate.text = [NSString stringWithFormat:@"Updated %@", upd_on];

        NSString *by = [self.data objectForKey:@"last_updated_by"];

        if (by) {
            self.updateUser.text = [NSString stringWithFormat:@"By %@", by];
        } else {
            self.updateUser.text = @"";
        }
    }    
}

- (NSString *)reformatLastUpdateDate:(NSString *)dateString
{
    if (!dateString) {
        return nil;
    }

    NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateFormatter *readFormatter = [[NSDateFormatter alloc] init];
    [readFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [readFormatter setCalendar:cal];
    [readFormatter setLocale:[NSLocale currentLocale]];
    NSDate *date = [readFormatter dateFromString:dateString];

    NSDateFormatter *writeFormatter = [[NSDateFormatter alloc] init];
    [writeFormatter setDateFormat:@"MMMM d, yyyy h:mm a"];
    [writeFormatter setCalendar:cal];
    [writeFormatter setLocale:[NSLocale currentLocale]];
    return [writeFormatter stringFromDate:date];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (pictureTaker == nil) {
        pictureTaker = [[OTMPictureTaker alloc] init];
    }
    
    [self.tableView setAllowsSelectionDuringEditing:YES];
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
         CGFloat aspect = image.size.height / image.size.width;
         CGFloat newWidth = 800.0;
         CGFloat newHeight = aspect * newWidth;
         UIGraphicsBeginImageContextWithOptions(CGSizeMake(newWidth, newHeight), YES, 0.0);
         [image drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
         image = UIGraphicsGetImageFromCurrentImageContext();
         UIGraphicsEndImageContext();
         
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
    allFields = [k mutableCopy];
    
    NSMutableArray *editableFields = [NSMutableArray array];

    OTMMapDetailCellRenderer *mapDetailCellRenderer = [[OTMMapDetailCellRenderer alloc] init];

    OTMEditMapDetailCellRenderer *mapEditCellRenderer = [[OTMEditMapDetailCellRenderer alloc] initWithDetailRenderer:mapDetailCellRenderer];
    
    mapEditCellRenderer.clickCallback = ^(OTMDetailCellRenderer *renderer) {
        [self performSegueWithIdentifier:@"changeLocation" sender:self];
    };

    NSArray *mapSection = [NSArray arrayWithObjects:mapEditCellRenderer,nil];
    [editableFields addObject:mapSection];

    OTMStaticClickCellRenderer *speciesRow = 
    [[OTMStaticClickCellRenderer alloc] initWithKey:@"tree.species_name"
                                      clickCallback:^(OTMDetailCellRenderer *renderer) 
    { 
        [self performSegueWithIdentifier:@"changeSpecies"
                                  sender:self];
    }];
    speciesRow.defaultName = @"Set Species";
    speciesRow.detailDataKey = @"tree.sci_name";
    
    OTMDetailCellRenderer *pictureRow = 
    [[OTMStaticClickCellRenderer alloc] initWithName:@"Change Tree Picture"
                                                 key:@""
                                       clickCallback:^(OTMDetailCellRenderer *renderer) 
    { 
        [self updatePicture];
    }];    
    
    NSArray *speciesAndPicSection = [NSArray arrayWithObjects:speciesRow,pictureRow,nil];
    [editableFields addObject:speciesAndPicSection];
    
    OTMLoginManager* loginManager = [SharedAppDelegate loginManager];
    OTMUser *user = loginManager.loggedInUser;

    
    for(int section=0;section < [allFields count];section++) {
        NSMutableArray *sectionArray = [[allFields objectAtIndex:section] mutableCopy];
        NSMutableArray *editSectionArray = [NSMutableArray array];
        
        for(int row=0;row < [sectionArray count]; row++) {
            OTMDetailCellRenderer *renderer = [OTMDetailCellRenderer cellRendererFromDict:[sectionArray objectAtIndex:row] user:user];
        
            if (renderer.editCellRenderer != nil) {
                [editSectionArray addObject:renderer.editCellRenderer];
                [txToEditRel addObject:[NSIndexPath indexPathForRow:row inSection:section]];
            } else {
                [txToEditRm addObject:[NSIndexPath indexPathForRow:row inSection:section]];
            }

            [sectionArray replaceObjectAtIndex:row withObject:renderer];
        }
                
        [allFields replaceObjectAtIndex:section withObject:sectionArray];
        [editableFields addObject:editSectionArray];
    }
    
    txToEditReload = txToEditRel;
    txToEditRemove = txToEditRm;
    editFields = editableFields;

    curFields = allFields;
}

- (IBAction)startOrCommitEditing:(id)sender
{
    OTMLoginManager* loginManager = [SharedAppDelegate loginManager];

    [loginManager presentModelLoginInViewController:self.parentViewController callback:^(BOOL success, OTMUser *aUser) {
        if (success) {
            loginManager.loggedInUser = aUser;
            [self toggleEditMode:YES];
        }
    }];
}

- (IBAction)cancelEditing:(id)sender
{
    [self toggleEditMode:NO];
}

- (void)toggleEditMode:(BOOL)saveChanges
{
    [self.activeField resignFirstResponder];
    
    // Edit mode represents the mode that we are transitioning to
    editMode = !editMode;
    
    if (editMode) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(startOrCommitEditing:)];

        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelEditing:)];

    } else {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStyleBordered target:self action:@selector(startOrCommitEditing:)];

        self.navigationItem.leftBarButtonItem = nil;
    }

    if (editMode) { // Tx to edit mode
        curFields = editFields;
        
        [self.tableView beginUpdates];
        
        [self.tableView deleteRowsAtIndexPaths:txToEditRemove
                              withRowAnimation:UITableViewRowAnimationFade];

        // There are 2 fixed sections to be added when editing: the mini map section and the species/photo section
        [self.tableView insertSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)]
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
        if (saveChanges) {
            for(NSArray *section in editFields) {
                for(OTMEditDetailCellRenderer *editFld in section) {
                    self.data = [editFld updateDictWithValueFromCell:data];
                }
            }
        }
        
        [self syncTopData];
        
        curFields = allFields;
        
        [self.tableView beginUpdates];
        
        // There are 2 fixed sections to be removed after editing: the mini map section and the species/photo section
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)]
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

        if (saveChanges) {
            OTMLoginManager* loginManager = [SharedAppDelegate loginManager];
            OTMUser *user = loginManager.loggedInUser;

            if ([self.data objectForKey:@"id"] == nil) { // No 'id' parameter indicates that this is a new plot/tree

                NSLog(@"Sending new tree data:\n%@", data);

                [[AZWaitingOverlayController sharedController] showOverlayWithTitle:@"Saving"];

                [[[OTMEnvironment sharedEnvironment] api] addPlotWithOptionalTree:data user:user callback:^(id json, NSError *err){

                    [[AZWaitingOverlayController sharedController] hideOverlay];

                    if (err == nil) {
                        [self.delegate viewController:self addedTree:data];

                    } else {
                        NSLog(@"Error adding tree: %@", err);
                        [[[UIAlertView alloc] initWithTitle:nil
                                                    message:@"Sorry. There was a problem saving the new tree."
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil] show];
                    }
                }];
            } else {
                NSLog(@"Updating existing plot/tree data:\n%@", data);

                [[AZWaitingOverlayController sharedController] showOverlayWithTitle:@"Saving"];

                [[[OTMEnvironment sharedEnvironment] api] updatePlotAndTree:data user:user callback:^(id json, NSError *err){

                    [[AZWaitingOverlayController sharedController] hideOverlay];

                    if (err == nil) {
                        self.data = [json mutableDeepCopy];
                        [delegate viewController:self editedTree:(NSDictionary *)data withOriginalLocation:originalLocation];
                        [self syncTopData];
                        [self.tableView reloadData];
                    } else {
                        NSLog(@"Error updating tree: %@\n %@", err, data);
                        [[[UIAlertView alloc] initWithTitle:nil
                                                    message:@"Sorry. There was a problem saving the updated tree details."
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil] show];
                    }
                }];
            }
        }
    }
    
    // No 'id' parameter indicates that this view was shown to edit a new plot/tree
    if ([self.data objectForKey:@"id"] == nil && !saveChanges) {
        [delegate treeAddCanceledByViewController:self];
    }

    // Need to reload all of the cells after animation is done
    double delayInMSeconds = 250;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInMSeconds * NSEC_PER_MSEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self.tableView reloadData];
    });
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"changeSpecies"]) {
        OTMSpeciesTableViewController *sVC = (OTMSpeciesTableViewController *)segue.destinationViewController;
        
        sVC.callback = ^(NSNumber *sId, NSString *name, NSString *scientificName) {
            [self.data setObject:sId forEncodedKey:@"tree.species"];
            [self.data setObject:name forEncodedKey:@"tree.species_name"];
            [self.data setObject:scientificName forEncodedKey:@"tree.sci_name"];
            [self syncTopData];

            [self.tableView reloadRowsAtIndexPaths:[NSArray
                                                    arrayWithObject:
                                                    [NSIndexPath
                                                     indexPathForRow:0
                                                     inSection:1]]
                                  withRowAnimation:UITableViewRowAnimationNone];
        };
    } else if ([segue.identifier isEqualToString:@"changeLocation"]) {
        OTMChangeLocationViewController *changeLocationViewController = segue.destinationViewController;
        // Trigger the view to load so all subviews are unarchived
        [changeLocationViewController view];

        changeLocationViewController.delegate = self;

        changeLocationViewController.navigationItem.title = @"Move Tree";

        CLLocationCoordinate2D center = [OTMTreeDictionaryHelper getCoordinateFromDictionary:data];

        [changeLocationViewController annotateCenter:center];
    } else if ([segue.identifier isEqualToString:@"fieldDetail"]) {
        NSIndexPath *indexPath = (NSIndexPath *)sender;
        id renderer = [[curFields objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        OTMFieldDetailViewController *fieldDetailViewController = segue.destinationViewController;
        fieldDetailViewController.data = data;
        fieldDetailViewController.fieldKey = [renderer dataKey];
        if ([renderer respondsToSelector:@selector(label)]) {
            fieldDetailViewController.fieldName = [renderer label];
        }
        fieldDetailViewController.ownerFieldKey = [renderer ownerDataKey];
        if ([renderer respondsToSelector:@selector(formatStr)]) {
            fieldDetailViewController.fieldFormatString = [renderer formatStr];
        }
        if ([renderer respondsToSelector:@selector(fieldName)] && [renderer respondsToSelector:@selector(fieldChoices)]) {
            fieldDetailViewController.choices = [[[OTMEnvironment sharedEnvironment] choices] objectForKey:[renderer fieldName]];
        } else {
            // The view controller uses the presence of this property to determine how
            // to display the value, so it must be nil'd out if ot os not a choices field
            fieldDetailViewController.choices = nil;
        }
        fieldDetailViewController.pendingEditsUpdatedCallback = ^(NSDictionary *updatedData){
            self.data = [updatedData mutableDeepCopy];
            [self syncTopData];
            [self.tableView reloadData];
            [delegate viewController:self editedTree:self.data withOriginalLocation:originalLocation]
            ;
        };
    }
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
    if (editMode) {
        Function1v clicker = [[[curFields objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] clickCallback];

        if (clicker) {
            clicker(self);
        }
    } else {
        if ([[tblView cellForRowAtIndexPath:indexPath] accessoryType] != UITableViewCellAccessoryNone)
        [self performSegueWithIdentifier:@"fieldDetail" sender:indexPath];
    }
    
    [tblView deselectRowAtIndexPath:indexPath animated:YES];
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
