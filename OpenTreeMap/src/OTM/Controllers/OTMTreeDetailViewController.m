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

@interface OTMTreeDetailViewController ()

@end

@implementation OTMTreeDetailViewController

@synthesize data, keys, tableView, address, species, lastUpdateDate, updateUser, imageView, pictureTaker, headerView, acell, delegate, originalLocation, originalData;

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
        NSString *addr = [self.data objectForKey:@"address"];
        if (!addr || (id)addr == [NSNull null] ||
            [addr isEqualToString:@""]) {
            self.address.text = @"No Address";
        } else {
            self.address.text = addr;
        }

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

        NSString *upd_on = [self reformatLastUpdateDate:
                                   [[self.data objectForKey:@"latest_update"] objectForKey:@"created"]];

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

    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.extendedLayoutIncludesOpaqueBars = NO;
    self.automaticallyAdjustsScrollViewInsets = NO;

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
         self.imageView.image = image;

         NSMutableDictionary *tree = [[self data] objectForKey:@"tree"];
         if (!tree || tree == (id)[NSNull null]) {
             tree = [NSMutableDictionary dictionary];
             [(id)[self data] setObject:tree forKey:@"tree"];
         }

         NSArray *photos = [tree objectForKey:@"images"];
         if (photos == nil) {
             photos = [NSArray array];
         }

         NSMutableDictionary *newPhotoInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                                           @"OTM-Mobile Photo", @"title",
                                                           image, @"data", nil];

         [tree setObject:[photos arrayByAddingObject:newPhotoInfo] forKey:@"images"];

     }];

}

- (void)setKeys:(NSArray *)k {
    allKeys = k;
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

    for(int section=0;section < [allFields count];section++) {
        NSMutableArray *sectionArray = [[allFields objectAtIndex:section] mutableCopy];
        NSMutableArray *editSectionArray = [NSMutableArray array];

        for(int row=0;row < [sectionArray count]; row++) {
            OTMDetailCellRenderer *renderer = [sectionArray objectAtIndex:row];

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

    self.navigationItem.rightBarButtonItem.enabled = [self canEditBothPlotAndTree];
}

- (IBAction)showTreePhotoFullscreen:(id)sender {
    NSArray *images = [[self.data objectForKey:@"tree"] objectForKey:@"images"];
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
}

- (void)enterEditModeIfAllowed {
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

            if (self.data[@"plot"][@"id"] == nil) { // No 'id' parameter indicates that this is a new plot/tree

                NSLog(@"Sending new tree data:\n%@", data);

                [[AZWaitingOverlayController sharedController] showOverlayWithTitle:@"Saving"];

                NSArray *pendingImageData = [self stripPendingImageData];
                [[[OTMEnvironment sharedEnvironment] api] addPlotWithOptionalTree:data user:user callback:^(id json, NSError *err){

                    [[AZWaitingOverlayController sharedController] hideOverlay];

                    if (err == nil) {
                        data = [json mutableDeepCopy];
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

                    if (err == nil) {
                        if (err == nil) {
                            [self pushImageData:pendingImageData newTree:NO];
                            self.data = [json mutableDeepCopy];
                            [delegate viewController:self editedTree:(NSDictionary *)data withOriginalLocation:originalLocation originalData:originalData];
                        }
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

- (NSArray *)stripPendingImageData {
    NSMutableArray *pending = [NSMutableArray array];
    NSArray *treePhotos;
    if ([data objectForKey:@"tree"] && [data objectForKey:@"tree"] != [NSNull null]) {
        treePhotos = [[data objectForKey:@"tree"] objectForKey:@"images"];
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
        [[data objectForKey:@"tree"] setObject:savedTreePhotos forKey:@"images"];
    }
    return pending;
}

- (void)pushImageData:(NSArray *)images newTree:(BOOL)newTree {
    if (images == nil || [images count] == 0) { // No images to push
        [[AZWaitingOverlayController sharedController] hideOverlay];
        if (newTree) {
            [self.delegate viewController:self addedTree:data];
        } else {
            [delegate viewController:self editedTree:(NSDictionary *)data withOriginalLocation:originalLocation originalData:originalData];
            [self syncTopData];
            [self.tableView reloadData];
        }
    } else {
        UIImage *image = [images objectAtIndex:0];
        NSArray *rest = [images subarrayWithRange:NSMakeRange(1,[images count]-1)];

        [[AZWaitingOverlayController sharedController] showOverlayWithTitle:@"Saving Images"];

        OTMLoginManager* loginManager = [SharedAppDelegate loginManager];
        OTMUser *user = loginManager.loggedInUser;

        [[[OTMEnvironment sharedEnvironment] api] setPhoto:image
                                              onPlotWithID:[[self.data objectForKey:@"id"] intValue]
                                                  withUser:user
                                                  callback:^(id json, NSError *err)
           {
               if (err == nil) {
                   [[NSNotificationCenter defaultCenter] postNotificationName:kOTMMapViewControllerImageUpdate
                                                                       object:image];
                   //TODO: Need to stick image back in here somehow
                   [self pushImageData:rest newTree:newTree];
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

        CLLocationCoordinate2D center = [OTMTreeDictionaryHelper getCoordinateFromDictionary:data];

        [changeLocationViewController annotateCenter:center];
    } else if ([segue.identifier isEqualToString:@"fieldDetail"]) {
        NSIndexPath *indexPath = (NSIndexPath *)sender;
        id renderer = [[curFields objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        OTMFieldDetailViewController *fieldDetailViewController = segue.destinationViewController;
        fieldDetailViewController.data = data;
        fieldDetailViewController.fieldKey = [renderer dataKey];
        fieldDetailViewController.ownerFieldKey = [renderer ownerDataKey];
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
            [delegate viewController:self editedTree:self.data withOriginalLocation:originalLocation originalData:originalData]
            ;
        };
    } else if ([segue.identifier isEqualToString:@"showImage"]) {
        OTMImageViewController *controller = segue.destinationViewController;
        [controller loadImage:sender];
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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (editMode) {
        // The view controller rearranges all the sections in the table view
        // when it is in edit mode, so the section labels no longer apply.
        return nil;
    } else {
        NSString *title = nil;
        NSDictionary *fieldSectionDict = [[[OTMEnvironment sharedEnvironment] fieldSections] objectAtIndex:section];
        if (fieldSectionDict) {
            if ([fieldSectionDict objectForKey:@"label"]) {
                if (![(NSString *)[fieldSectionDict objectForKey:@"label"] isEqualToString:@""]) {
                    title = [fieldSectionDict objectForKey:@"label"];
                }
            }
        }
        return title;
    }
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

- (BOOL)canDeletePlot
{
    return [[[[data objectForKey:@"perm"] objectForKey:@"plot"] objectForKey:@"can_delete"] intValue] == 1;
}

- (BOOL)canDeleteTree
{
    return [[[[data objectForKey:@"perm"] objectForKey:@"tree"] objectForKey:@"can_delete"] intValue] == 1;
}

- (BOOL)canEditThing:(NSString *)thing {
    NSDictionary *perms = [data objectForKey:@"perm"];
    if (perms && [perms objectForKey:thing]) {
        return [[[perms objectForKey:thing] objectForKey:@"can_edit"] intValue] == 1;
    } else { // If there aren't specific permissions, allow it
        return YES;
    }
}

- (BOOL)canEditEitherPlotOrTree {
    return [self canEditThing:@"plot"] ||
        [self canEditThing:@"tree"];
}

- (BOOL)canEditBothPlotAndTree {
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
    if (buttonIndex == 0) { // The destructive button is always at index 0
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
