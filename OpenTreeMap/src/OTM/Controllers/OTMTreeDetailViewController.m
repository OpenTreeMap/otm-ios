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

#import "OTMTreeDetailViewController.h"
#import "OTMDetailTableViewCell.h"
#import "OTMSpeciesTableViewController.h"
#import "OTMFormatter.h"
#import "OTMMapViewController.h"
#import "OTMDetailCellRenderer.h"
#import "AZWaitingOverlayController.h"
#import "OTMChangeLocationViewController.h"
#import "OTMTreeDictionaryHelper.h"
#import "OTMFieldDetailViewController.h"
#import "OTMImageViewController.h"
#import "OTMChoicesDetailCellRenderer.h"
#import "UIView+Borders.h"

@interface OTMTreeDetailViewController ()

@end

@implementation OTMTreeDetailViewController

@synthesize data, keys, tableView, address, species, lastUpdateDate, updateUser, imageView, pictureTaker, headerView, acell, delegate, originalLocation, originalData;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self syncTopData];
    self.tableView.contentInset = UIEdgeInsetsZero;
    self.automaticallyAdjustsScrollViewInsets = NO;
}

-(void)syncTopData
{
    if (self.data) {
        self.address.text = [[self buildAddressStringFromPlotDictionary:self.data] uppercaseString];

        NSDictionary *pendingSpeciesEditDict = [[self.data objectForKey:@"pending_edits"] objectForKey:@"tree.species.common_name"];
        if (pendingSpeciesEditDict) {
            NSDictionary *latestEdit = [[pendingSpeciesEditDict objectForKey:@"pending_edits"] objectAtIndex:0];
            self.species.text = [[latestEdit objectForKey:@"related_fields"] objectForKey:@"tree.species_name"];
        } else {
            if ([self.data decodeKey:@"tree.species.common_name"]) {
                self.species.text = [self.data decodeKey:@"tree.species.common_name"];
            } else {
                self.species.text = @"Missing Species";
            }
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
    [readFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SZ"];
    [readFormatter setCalendar:cal];
    [readFormatter setLocale:[NSLocale currentLocale]];
    NSDate *date = [readFormatter dateFromString:dateString];

    NSDateFormatter *writeFormatter = [[NSDateFormatter alloc] init];
    [writeFormatter setDateFormat:[[OTMEnvironment sharedEnvironment] dateFormat]];
    [writeFormatter setCalendar:cal];
    [writeFormatter setLocale:[NSLocale currentLocale]];
    return [writeFormatter stringFromDate:date];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [headerView addBottomBorder];

    if (pictureTaker == nil) {
        pictureTaker = [[OTMPictureTaker alloc] init];
    }

}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    // Zero out the height of the first group so it sticks to the top of the
    // view.
    if (section == 0) {
        return 0.01f;
    }
    return self.tableView.rowHeight;
}

- (void)resetHeaderPosition
{
    if (editMode) {
        [UIView animateWithDuration:0.3 animations:^{
            // Offset the header up by 3x its height so it moves totally off the
            // screen. Otherwise it is visible behind the status bar at the top.
            self.headerView.frame = CGRectOffset(self.headerView.frame, 0, -3 * self.headerView.frame.size.height);

            // Make the table view bigger by the size of the header to fill the
            // leftover space.
            CGRect frame = self.tableView.frame;
            frame.size.height = frame.size.height + self.headerView.frame.size.height;
            self.tableView.frame = frame;
            self.tableView.frame = CGRectOffset(frame, 0, -self.headerView.frame.size.height);
         }];
    } else {
        [UIView animateWithDuration:0.3 animations:^{
            // Reverse what we did above.
            self.headerView.frame = CGRectOffset(self.headerView.frame, 0, 3 * self.headerView.frame.size.height);
            CGRect frame = self.tableView.frame;
            frame.size.height = frame.size.height - self.headerView.frame.size.height;
            self.tableView.frame = frame;
            self.tableView.frame = CGRectOffset(frame, 0, self.headerView.frame.size.height);
         }];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)updatePicture
{
    [pictureTaker getPictureInViewController:self
                                    callback:^(UIImage *image)
     {
         self.imageView.image = image;

         NSMutableDictionary *tree = [[self data] objectForKey:@"tree"];
         if (!tree || tree == (id)[NSNull null]) {
             tree = [NSMutableDictionary dictionary];
             [(id)[self data] setObject:tree forKey:@"tree"];
         }

         NSArray *photos = [data objectForKey:@"images"];
         if (photos == nil) {
             photos = [NSArray array];
         }

         NSDictionary *newPhotoInfo = [NSDictionary
                                              dictionaryWithObjectsAndKeys:
                                              @"OTM-Mobile Photo", @"title", image, @"data", nil];

         [data setObject:[photos arrayByAddingObject:newPhotoInfo] forKey:@"images"];

     }];
}

- (void)setKeys:(NSArray *)k
{
    _fieldsWithSectionTitles = [[NSMutableArray alloc] init];
    _editableFieldsWithSectionTitles = [[NSMutableArray alloc] init];
    _dKeys = [NSArray arrayWithObjects: @"title", @"cells", nil];
    NSArray *titles = [[OTMEnvironment sharedEnvironment] sectionTitles];

    for (int i = 0; i < [k count]; i++) {
        NSArray *dVals = [NSArray arrayWithObjects: [titles objectAtIndex:i], [k objectAtIndex:i], nil];
        NSDictionary *cellsAndSection = [[NSDictionary alloc] initWithObjects:dVals forKeys:_dKeys];
        [_fieldsWithSectionTitles addObject:cellsAndSection];
    }

    // Map cells.
    OTMMapDetailCellRenderer *mapDetailCellRenderer = [[OTMMapDetailCellRenderer alloc] init];
    OTMEditMapDetailCellRenderer *mapEditCellRenderer = [[OTMEditMapDetailCellRenderer alloc] initWithDetailRenderer:mapDetailCellRenderer];

    mapEditCellRenderer.clickCallback = ^(OTMDetailCellRenderer *renderer) {
        [self performSegueWithIdentifier:@"changeLocation" sender:self];
    };

    // Add the editable map cell to the editable fields data structure.
    NSArray *mapSection = [NSArray arrayWithObjects:mapEditCellRenderer,nil];
    NSDictionary *mapSectionDict;
    mapSectionDict = [[NSDictionary alloc] initWithObjects:[NSArray arrayWithObjects: @"", mapSection, nil] forKeys:_dKeys];
    [_editableFieldsWithSectionTitles insertObject:mapSectionDict atIndex:0];

    // Create and add a read only map cell.
    OTMMapDetailCellRenderer *readOnlyMapDetailCellRenderer = [[OTMMapDetailCellRenderer alloc] init];
    readOnlyMapDetailCellRenderer.cellHeight = 120;

    // Add the read only map cell to the standard fields data structure.
    NSArray *readOnlyMapSection = [NSArray arrayWithObject:readOnlyMapDetailCellRenderer];
    mapSectionDict = [[NSDictionary alloc] initWithObjects:[NSArray arrayWithObjects: @"", readOnlyMapSection, nil] forKeys:_dKeys];
    [_fieldsWithSectionTitles insertObject:mapSectionDict atIndex:0];


    // If the photo field is writable display a cell with a callback otherwise
    // the callback does nothing. Same thing for the speices cell.
    OTMStaticClickCellRenderer *speciesRow = nil;
    OTMDetailCellRenderer *pictureRow = nil;
    if ([[OTMEnvironment sharedEnvironment] speciesFieldIsWritable]) {
        speciesRow = [[OTMStaticClickCellRenderer alloc] initWithKey:@"tree.species_name"
                                                       clickCallback:^(OTMDetailCellRenderer *renderer)
        {
            [self performSegueWithIdentifier:@"changeSpecies"
                                      sender:self];
        }];
        NSString *spName;
        @try {
            // This key doesn't exist if the species is not set.
            spName = [[[self.data objectForKey:@"tree"] objectForKey:@"species"] objectForKey:@"common_name"];
        }
        @catch (NSException *exception) {
            spName = @"not set";
        }
        @finally {
            // If the string came back empty we assume that the species is not set.
            if (spName == nil || [spName isEqualToString:@""]) {
                spName = @"not set";
            }
        }
        speciesRow.defaultName = [@"Set Species" stringByAppendingFormat: @" (%@)", spName];
        speciesRow.detailDataKey = @"tree.sci_name";
    } else {
        speciesRow = [[OTMStaticClickCellRenderer alloc] initWithKey:@"tree.species_name"
                                                       clickCallback:^(OTMDetailCellRenderer *renderer) {}];

        speciesRow.defaultName = @"Species cannot be changed";
        speciesRow.detailDataKey = @"tree.sci_name";
    }

    if ([[OTMEnvironment sharedEnvironment] photoFieldIsWritable]) {
        pictureRow = [[OTMStaticClickCellRenderer alloc]
                      initWithName:@"Tree Picture"
                               key:@""
                     clickCallback:^(OTMDetailCellRenderer *renderer)
        {
            [self updatePicture];
        }];
    } else {
        pictureRow = [[OTMStaticClickCellRenderer alloc]
                      initWithName:@"Picture cannot be changed"
                               key:@""
                     clickCallback:^(OTMDetailCellRenderer *renderer) {}];
    }

    // Species and photo cells get added to the structure for editable fields.
    NSArray *speciesAndPicSection = [NSArray arrayWithObjects: speciesRow, pictureRow, nil];
    NSDictionary *speciesAndPicsDict = [[NSDictionary alloc] initWithObjects:[[NSArray alloc] initWithObjects:@"Tree Details", speciesAndPicSection, nil] forKeys:_dKeys];
    [_editableFieldsWithSectionTitles addObject:speciesAndPicsDict];

    // Loop through cells and add editable cells to the editable fields structure.
    for (NSDictionary *dict in _fieldsWithSectionTitles) {
        NSMutableArray *eCells = [[NSMutableArray alloc] init];
        for (OTMDetailCellRenderer *cell in [dict valueForKey:@"cells"]) {
            if (cell.editCellRenderer != nil) {
                [eCells addObject:cell.editCellRenderer];
            }
        }
        if ([eCells count] > 0) {
            NSArray *editCells = [eCells copy];
            NSString *title = [dict valueForKey:@"title"];
            NSDictionary *editSectionDict = [[NSDictionary alloc] initWithObjects:[NSArray arrayWithObjects: title, editCells, nil] forKeys:_dKeys];
            [_editableFieldsWithSectionTitles addObject:editSectionDict];
        }
    }

    // Set the inited property on all the editable cells.
    for (NSDictionary *dict in _editableFieldsWithSectionTitles) {
        for (OTMEditDetailCellRenderer *cell in [dict valueForKey:@"cells"]) {
            cell.inited = NO;
        }
    }

    curFields = _fieldsWithSectionTitles;
    self.navigationItem.rightBarButtonItem.enabled = [self canEditBothPlotAndTree];
}

- (void)setEcoKeys:(NSArray *)ecoKeys
{
    for (int i = 0; i < [ecoKeys count]; i++) {
        NSMutableArray *ecoFieldRenderers = [[NSMutableArray alloc] init];
        NSArray *ecoFields = [ecoKeys objectAtIndex:i];
        for (int j = 0; j < [ecoFields count]; j++) {
            [ecoFieldRenderers addObject:[ecoFields objectAtIndex:j]];
        }
        NSDictionary *ecoSectionDict = [[NSDictionary alloc] initWithObjects:[NSArray arrayWithObjects: @"Ecosystem benefits", ecoFieldRenderers, nil] forKeys:_dKeys];
        [_fieldsWithSectionTitles addObject:ecoSectionDict];
    }
}

- (IBAction)showTreePhotoFullscreen:(id)sender
{
    NSArray *images = [self.data objectForKey:@"images"];
    NSString* imageURL = [[images objectAtIndex:0] objectForKey:@"url"];

    if (imageURL) {
        [self performSegueWithIdentifier:@"showImage" sender:imageURL];
    }
}

- (IBAction)startOrCommitEditing:(id)sender
{
    OTMLoginManager* loginManager = [SharedAppDelegate loginManager];
    OTMUser *prevUser = loginManager.loggedInUser;

    [loginManager presentModelLoginInViewController:self.parentViewController callback:^(BOOL success, OTMUser *aUser) {
        if (success) {
            if (prevUser == nil) {
                [self setKeys:allKeys];
                [[[OTMEnvironment sharedEnvironment] api] getPlotInfo:[self.data[@"plot"][@"id"] intValue]
            user:aUser
            callback:^(id newData, NSError *error) {
                        // need to reload all cells
                        [self setKeys:[[OTMEnvironment sharedEnvironment] fieldKeys]];

                        // On main thread?
                        [self.tableView reloadData];

                        self.data = newData;
                        [self enterEditModeIfAllowed];

            }];
            } else {
                loginManager.loggedInUser = aUser;
                [self enterEditModeIfAllowed];
            }
        }
    }];
    [self.tableView reloadData];
}

- (void)enterEditModeIfAllowed
{
    if ([self canEditBothPlotAndTree]) {
        [self toggleEditMode:YES];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Can't edit this tree"
                                   message:@"You don't have permission to edit this tree"
                                  delegate:nil
                          cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
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
        self.navigationItem.rightBarButtonItem =
            [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                             style:UIBarButtonItemStyleDone
                                            target:self
                                            action:@selector(startOrCommitEditing:)];

        self.navigationItem.leftBarButtonItem =
            [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                             style:UIBarButtonItemStyleBordered
                                            target:self
                                            action:@selector(cancelEditing:)];

    } else {
        self.navigationItem.rightBarButtonItem =
            [[UIBarButtonItem alloc] initWithTitle:@"Edit"
                                             style:UIBarButtonItemStyleBordered
                                            target:self
                                            action:@selector(startOrCommitEditing:)];

        self.navigationItem.leftBarButtonItem = nil;
    }

    if (editMode) {
        curFields = _editableFieldsWithSectionTitles;
        [self.tableView reloadData];
    } else {
        if (saveChanges) {
            for (NSArray *section in _editableFieldsWithSectionTitles) {
                for(OTMEditDetailCellRenderer *editFld in [section valueForKey:@"cells"]) {
                    self.data = [editFld updateDictWithValueFromCell:data];
                }
            }
        }

        [self syncTopData];
        curFields = _fieldsWithSectionTitles;
        [self.tableView reloadData];

        if (saveChanges) {
            OTMLoginManager* loginManager = [SharedAppDelegate loginManager];
            OTMUser *user = loginManager.loggedInUser;

            if (self.data[@"plot"][@"id"] == nil) {
                // No 'id' parameter indicates that this is a new plot/tree
                NSLog(@"Sending new tree data:\n%@", data);

                [[AZWaitingOverlayController sharedController] showOverlayWithTitle:@"Saving"];

                NSArray *pendingImageData = [self stripPendingImageData];
                [[[OTMEnvironment sharedEnvironment] api] addPlotWithOptionalTree:data user:user callback:^(id json, NSError *err){

                    [[AZWaitingOverlayController sharedController] hideOverlay];

                    if (err == nil) {
                        data = [json mutableDeepCopy];
                        [[OTMEnvironment sharedEnvironment] setGeoRev:data[@"geoRevHash"]];
                        [self pushImageData:pendingImageData newTree:YES];
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

                NSArray *pendingImageData = [self stripPendingImageData];
                [[[OTMEnvironment sharedEnvironment] api] updatePlotAndTree:data user:user callback:^(id json, NSError *err){

                    [[AZWaitingOverlayController sharedController] hideOverlay];

                    UIImage *latestPhoto = [pendingImageData count] > 0 ? [pendingImageData objectAtIndex:0] : nil;

                    if (err == nil) {
                        self.data = [json mutableDeepCopy];
                        [self pushImageData:pendingImageData newTree:NO];
                        [[OTMEnvironment sharedEnvironment] setGeoRev:data[@"geoRevHash"]];
                        [delegate viewController:self
                                      editedTree:(NSDictionary *)data
                            withOriginalLocation:originalLocation
                                    originalData:originalData
                                       withPhoto:latestPhoto];
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

    // No 'id' parameter indicates that this view was shown to edit a new
    // plot/tree.
    if ([[self.data objectForKey:@"plot"] objectForKey:@"id"] == nil && !saveChanges) {
        [delegate treeAddCanceledByViewController:self];
    }
    [self.tableView reloadData];
    [self resetHeaderPosition];
}

- (NSArray *)stripPendingImageData
{
    NSMutableArray *pending = [NSMutableArray array];
    NSArray *treePhotos;
    if ([data objectForKey:@"tree"] && [data objectForKey:@"tree"] != [NSNull null]) {
        treePhotos = [data objectForKey:@"images"];
    }
    NSMutableArray *savedTreePhotos = [NSMutableArray array];
    if (treePhotos) {
        for(NSDictionary *treePhoto in treePhotos) {
            if ([treePhoto objectForKey:@"id"] == nil) {
                [pending addObject:[treePhoto objectForKey:@"data"]];
            } else {
                [savedTreePhotos addObject:treePhoto];
            }
        }
        [data setObject:savedTreePhotos forKey:@"images"];
    }
    return pending;
}

- (void)pushImageData:(NSArray *)images newTree:(BOOL)newTree
{
    [self pushImageData:images newTree:newTree latestImage:nil];
}

- (void)pushImageData:(NSArray *)images
              newTree:(BOOL)newTree
          latestImage:(UIImage *)latestImage
{
    if (images == nil || [images count] == 0) { // No images to push
        [[AZWaitingOverlayController sharedController] hideOverlay];
        if (newTree) {
            [self.delegate viewController:self addedTree:data withPhoto:latestImage];
        } else {
            [delegate viewController:self editedTree:(NSDictionary *)data withOriginalLocation:originalLocation originalData:originalData withPhoto:latestImage];
            [self syncTopData];
            [self.tableView reloadData];
        }
    } else {
        UIImage *image = [images objectAtIndex:0];
        NSArray *rest = [images subarrayWithRange:NSMakeRange(1,[images count]-1)];

        [[AZWaitingOverlayController sharedController] showOverlayWithTitle:@"Saving Images"];

        OTMLoginManager* loginManager = [SharedAppDelegate loginManager];
        OTMUser *user = loginManager.loggedInUser;

        NSInteger plotid = [self.data[@"plot"][@"id"] intValue];

        [[[OTMEnvironment sharedEnvironment] api] setPhoto:image
                                              onPlotWithID:plotid
                                                  withUser:user
                                                  callback:^(id json, NSError *err)
           {
               if (err == nil) {
                   [[NSNotificationCenter defaultCenter] postNotificationName:kOTMMapViewControllerImageUpdate
                                                                       object:image];
                   //TODO: Need to stick image back in here somehow
                   [self pushImageData:rest newTree:newTree latestImage:image];
               } else {
                   [[AZWaitingOverlayController sharedController] hideOverlay];
                   NSLog(@"Error adding photo to tree: %@\n %@", err, data);
                   [[[UIAlertView alloc] initWithTitle:nil
                                               message:@"Sorry. There was a problem saving the updated tree photos."
                                              delegate:nil
                                     cancelButtonTitle:@"OK"
                                     otherButtonTitles:nil] show];

               }
           }];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"changeSpecies"]) {
        OTMSpeciesTableViewController *speciesTableViewController = segue.destinationViewController;
        speciesTableViewController.delegate = self;

        OTMSpeciesTableViewController *sVC = (OTMSpeciesTableViewController *)segue.destinationViewController;

        sVC.callback = ^(NSDictionary *sdict) {
            [self.data setObject:sdict forEncodedKey:@"tree.species"];
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

        CLLocationCoordinate2D center = [OTMTreeDictionaryHelper getCoordinateFromDictionary:data[@"plot"]];

        [changeLocationViewController annotateCenter:center];
    } else if ([segue.identifier isEqualToString:@"fieldDetail"]) {

        // This feature is currently dormant. Code has been left as is because
        // it is not causing issues and the feature will return. LL 2014-07-14.

        NSIndexPath *indexPath = (NSIndexPath *)sender;
        id renderer = [[[curFields objectAtIndex:indexPath.section] valueForKey:@"cells" ] objectAtIndex:indexPath.row];
        OTMFieldDetailViewController *fieldDetailViewController = segue.destinationViewController;
        fieldDetailViewController.data = data;
        fieldDetailViewController.fieldKey = [renderer dataKey];
        fieldDetailViewController.ownerFieldKey = [renderer ownerDataKey];
        if ([renderer respondsToSelector:@selector(fieldName)] && [renderer respondsToSelector:@selector(fieldChoices)]) {
            fieldDetailViewController.choices = [renderer fieldChoices];
        } else {
            // The view controller uses the presence of this property to determine how
            // to display the value, so it must be nil'd out if ot os not a choices field
            fieldDetailViewController.choices = nil;
        }
        fieldDetailViewController.pendingEditsUpdatedCallback = ^(NSDictionary *updatedData){
            self.data = [updatedData mutableDeepCopy];
            [self syncTopData];
            [self.tableView reloadData];
            [delegate viewController:self editedTree:self.data withOriginalLocation:originalLocation originalData:originalData]
            ;
        };
    } else if ([segue.identifier isEqualToString:@"showImage"]) {
        OTMImageViewController *controller = segue.destinationViewController;
        [controller loadImage:sender forPlot:self.data];
    }
}


- (void)speciesDetailsViewControllerDidUpdate:(OTMSpeciesTableViewController *)controller
                        withSpeciesCommonName:(NSString *) newSpeciesCommonName
                            andScientificName:(NSString *) newSpeciesScientificName
{
    // Update the edit cell label with the new name.
    [self updateSpeciesEditCellWithString: newSpeciesCommonName];

    // As the delegate for behavior of the detail screen we are responsible for
    // popping the other controller.
    [self.navigationController popViewControllerAnimated:YES];
}

/**
 * Given a new species string, update the set species cell and re-render in in
 * the table.
 */
- (void) updateSpeciesEditCellWithString:(NSString *) speciesString
{
    NSString *label = [@"Set Species" stringByAppendingFormat:@" (%@)", speciesString];

    // Find the index of the set species cell.
    NSIndexPath *indexPath = [self updateSpeciesEditCellLabelWithString:label];

    if (indexPath != nil) {
        [self.tableView beginUpdates];
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                              withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView endUpdates];
    }
}

/**
 * Update the set species edit cell rederer so that if the cell is re-rendered a
 * new label will appear. If the cell is in the list of current fields return
 * its index path.
 *
 * Return nil if the cell was not found.
 */
- (NSIndexPath *) updateSpeciesEditCellLabelWithString:(NSString *) newLabel
{
    // Loop through all the current cells until the species_name data key is
    // found. If it is update the label and return the indexpath.
    for (int i = 0; i < [curFields count]; i++) {
        for (int j = 0; j < [[[curFields objectAtIndex:i] valueForKey:@"cells"] count]; j++) {
            OTMStaticClickCellRenderer *cell = [[[curFields objectAtIndex:i] valueForKey:@"cells"] objectAtIndex:j];
            if ([[cell dataKey] isEqualToString:@"tree.species_name"]) {
                cell.defaultName = newLabel;
                return [NSIndexPath indexPathForItem:j inSection:i];
            }
        }
    }
    return nil;
}


#pragma mark -
#pragma mark UITableViewDelegate/DataSource methods

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)path
{
    return UITableViewCellEditingStyleNone;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [curFields count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[curFields objectAtIndex:section] valueForKey:@"cells"] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [[curFields objectAtIndex:section] valueForKey:@"title"];
}

- (void)tableView:(UITableView *)tblView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editMode) {
        Function1v clicker = [[[[curFields objectAtIndex:indexPath.section] valueForKey:@"cells"] objectAtIndex:indexPath.row] clickCallback];

        if (clicker) {
            clicker(self);
        }
    } else {
        if ([[tblView cellForRowAtIndexPath:indexPath] accessoryType] != UITableViewCellAccessoryNone)
        [self performSegueWithIdentifier:@"fieldDetail" sender:indexPath];
    }

    [tblView deselectRowAtIndexPath:indexPath animated:YES];
}

 - (CGFloat)tableView:(UITableView *)tblView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [[[[curFields objectAtIndex:indexPath.section] valueForKey:@"cells"] objectAtIndex:indexPath.row] cellHeight];
}

- (UITableViewCell *)tableView:(UITableView *)tblView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OTMDetailCellRenderer *renderer = [[[curFields objectAtIndex:indexPath.section] valueForKey:@"cells"] objectAtIndex:indexPath.row];
    UITableViewCell *cell = [renderer prepareCell:self.data inTable:tblView];
    if ([cell respondsToSelector:@selector(setTfDelegate:)]) {
        [cell performSelector:@selector(setTfDelegate:) withObject:self];
    }

    return cell;
}

- (BOOL)canDeletePlot
{
    return [[[[data objectForKey:@"perm"] objectForKey:@"plot"] objectForKey:@"can_delete"] intValue] == 1;
}

- (BOOL)canDeleteTree
{
    return [[[[data objectForKey:@"perm"] objectForKey:@"tree"] objectForKey:@"can_delete"] intValue] == 1;
}

- (BOOL)canEditThing:(NSString *)thing
{
    NSDictionary *perms = [data objectForKey:@"perm"];
    if (perms && [perms objectForKey:thing]) {
        return [[[perms objectForKey:thing] objectForKey:@"can_edit"] intValue] == 1;
    } else { // If there aren't specific permissions, allow it
        return YES;
    }
}

- (BOOL)canEditEitherPlotOrTree
{
    return [self canEditThing:@"plot"] ||
        [self canEditThing:@"tree"];
}

- (BOOL)canEditBothPlotAndTree
{
    return [self canEditThing:@"plot"] &&
        [self canEditThing:@"tree"];
}

- (BOOL)cannotDeletePlotOrTree
{
    return !([self canDeletePlot] || [self canDeleteTree]);
}

- (BOOL)shouldNotShowDeleteButtonsInFooterForSection:(NSInteger)section ofTableView:(UITableView *)aTableView
{
    return !(editMode && ([self numberOfSectionsInTableView:aTableView]- 1) == section);
}

- (CGFloat)footerHeight
{
    CGFloat height = 0;
    if ([self canDeletePlot]) {
        height += 74;
    }
    if ([self canDeleteTree]) {
        height += 74;
    }
    return height;
}

- (UIButton *)createDeleteButtonWithTitle:(NSString *)title yCoord:(CGFloat)y action:(SEL)action
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setFrame:CGRectMake(10, y, 300, 44)];
    [button setBackgroundImage:[UIImage imageNamed:@"button_glass_red"] forState:UIControlStateNormal];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (UIView *)tableView:(UITableView *)aTableView viewForFooterInSection:(NSInteger)section
{
    if ([self shouldNotShowDeleteButtonsInFooterForSection:section ofTableView:aTableView]) {
        return nil;
    }

    if ([self cannotDeletePlotOrTree]) {
        return nil;
    }

    CGFloat height = [self footerHeight];
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0,0,320,height)];
    CGFloat deleteButtonY = 0;

    if ([self canDeleteTree]) {
        [footer addSubview:[self createDeleteButtonWithTitle:@"Remove Tree"
                                                      yCoord:deleteButtonY
                                                      action:@selector(deleteTreeTapped:)]];
        deleteButtonY += 64;
    }

    if ([self canDeletePlot]) {
        [footer addSubview:[self createDeleteButtonWithTitle:@"Remove Planting Site"
                                                      yCoord:deleteButtonY
                                                      action:@selector(deletePlotTapped:)]];
    }

    return footer;
}

- (CGFloat)tableView:(UITableView *)aTableView heightForFooterInSection:(NSInteger)section
{
    if (editMode && ([self numberOfSectionsInTableView:aTableView]- 1) == section) {
        return [self footerHeight];
    } else {
        return 0.0;
    }
}

- (void)deleteTreeTapped:(id)sender
{
    deleteType = @"tree";
    [self showActionSheet];
}

- (void)deletePlotTapped:(id)sender
{
    deleteType = @"plot";
    [self showActionSheet];
}

- (void)showActionSheet
{
    NSString *title;
    NSString *destructiveButtonTitle;
    if ([deleteType isEqual:@"tree"]) {
        title = @"Remove the tree from this planting site?";
        destructiveButtonTitle = @"Remove Tree";
    } else if ([deleteType isEqual:@"plot"]) {
        title = @"Remove this planting site?";
        destructiveButtonTitle = @"Remove Planting Site";
    }

    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:title delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:destructiveButtonTitle otherButtonTitles:nil];
    [actionSheet showFromTabBar:self.tabBarController.tabBar];
}

- (void)deleteTreeFromPlot:(NSInteger)plotId user:(OTMUser *)user
{
    [[AZWaitingOverlayController sharedController] showOverlayWithTitle:@"Removing"];
    [[[OTMEnvironment sharedEnvironment] api] deleteTreeFromPlot:plotId user:user callback:^(id json, NSError *error) {
        [[AZWaitingOverlayController sharedController] hideOverlay];
        if (!error) {
            self.data = [json mutableDeepCopy];
            [delegate viewController:self editedTree:(NSDictionary *)self.data
                withOriginalLocation:originalLocation originalData:originalData];
            [self toggleEditMode:NO];
        } else {
            [[AZWaitingOverlayController sharedController] hideOverlay];
            NSLog(@"Error deleting tree: %@", [error description]);
            [UIAlertView showAlertWithTitle:nil message:@"There was a problem removing the tree." cancelButtonTitle:@"OK"otherButtonTitle:nil callback:nil];
        }
    }];
}

- (void)deletePlot:(NSInteger)plotId user:(OTMUser *)user
{
    [[AZWaitingOverlayController sharedController] showOverlayWithTitle:@"Removing"];
    [[[OTMEnvironment sharedEnvironment] api] deletePlot:plotId user:user callback:^(id json, NSError *error) {
        [[AZWaitingOverlayController sharedController] hideOverlay];
        if (!error) {
            [delegate plotDeletedByViewController:self];
            [self toggleEditMode:NO];
        } else {
            [[AZWaitingOverlayController sharedController] hideOverlay];
            NSLog(@"Error deleting plot: %@", [error description]);
            [UIAlertView showAlertWithTitle:nil message:@"There was a problem removing the planting site." cancelButtonTitle:@"OK"otherButtonTitle:nil callback:nil];

        }
    }];
}

#pragma mark -
#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) { // @MAGIC The destructive button is always at index 0
        NSInteger plotId = [[data objectForKey:@"id"] intValue];
        OTMUser *user = [[SharedAppDelegate loginManager] loggedInUser];
        if ([deleteType isEqual:@"tree"]) {
            [self deleteTreeFromPlot:plotId user:user];
        } else if ([deleteType isEqual:@"plot"]) {
            [self deletePlot:plotId user:user];
        }
    }
}

@end
