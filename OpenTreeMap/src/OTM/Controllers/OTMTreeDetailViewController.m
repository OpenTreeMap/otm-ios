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
#import "OTMLoadMoreCell.h"
#import "OTMUdfCollectionCell.h"

@interface OTMTreeDetailViewController ()

@end

static int tempId = 0;

@implementation OTMTreeDetailViewController

@synthesize data, keys, tableView, address, species, lastUpdateDate, updateUser,
            imageView, pictureTaker, headerView, acell, delegate,
            originalLocation, originalData;

NSString * const UdfNewDataCreatedNotification = @"UdfNewDataCreatedNotification";

+ (int) tempId { return tempId; }

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self syncTopData];
    self.tableView.contentInset = UIEdgeInsetsZero;
    self.automaticallyAdjustsScrollViewInsets = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear: animated];
    if (self.startInEditMode) {
        [self startOrCommitEditing:self];
        self.startInEditMode = NO;
    }
}

- (void)syncTopData
{
    if (self.data) {
        self.address.text = [[self buildAddressStringFromPlotDictionary:self.data] uppercaseString];

        NSDictionary *pendingSpeciesEditDict = [[self.data objectForKey:@"pending_edits"] objectForKey:@"tree.species.common_name"];
        if (pendingSpeciesEditDict) {
            NSDictionary *latestEdit = [[pendingSpeciesEditDict objectForKey:@"pending_edits"] objectAtIndex:0];
            self.species.text = [[latestEdit objectForKey:@"related_fields"] objectForKey:@"tree.species_name"];
        } else {
            // "title" contains the species common name, or "Missing Species", or "Empty Planting Site"
            self.species.text = self.data[@"title"];
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
    
    self.screenName = @"Tree Detail";  // for Google Analytics

    [headerView addBottomBorder];

    if (pictureTaker == nil) {
        pictureTaker = [[OTMPictureTaker alloc] init];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(addNewUdf:)
                                                 name:UdfNewDataCreatedNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateUdf:)
                                                 name:UdfUpdateNotification
                                               object:nil];


}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    // Zero out the height of the first group so it sticks to the top of the
    // view. For some reason 0.01f works but 0.00f did nothing. I suspect this
    // has to do with the fact that this method must return a non-negative
    // value. Might be that the docs are misleading and it actually must return
    // a positive value. Either way this works as you would expect returning
    // zero to work.
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
    _dKeys = [NSArray arrayWithObjects:@"title", @"cells", nil];
    NSArray *titles = [[OTMEnvironment sharedEnvironment] sectionTitles];

    for (int i = 0; i < [k count]; i++) {
        NSArray *dVals = [NSArray arrayWithObjects:[titles objectAtIndex:i], [k objectAtIndex:i], nil];
        NSDictionary *cellsAndSection = [[NSDictionary alloc] initWithObjects:dVals forKeys:_dKeys];
        [_fieldsWithSectionTitles addObject:cellsAndSection];
    }

    // Map cells.
    OTMMapDetailCellRenderer *mapDetailCellRenderer = [[OTMMapDetailCellRenderer alloc] init];
    OTMEditMapDetailCellRenderer *mapEditCellRenderer = [[OTMEditMapDetailCellRenderer alloc] initWithDetailRenderer:mapDetailCellRenderer];

    mapEditCellRenderer.clickCallback = ^(UIViewController *aController,  NSMutableDictionary *dict) {
        [self performSegueWithIdentifier:@"changeLocation" sender:self];
    };

    // Add the editable map cell to the editable fields data structure.
    NSArray *mapSection = [NSArray arrayWithObjects:mapEditCellRenderer,nil];
    NSDictionary *mapSectionDict;
    mapSectionDict = [[NSDictionary alloc] initWithObjects:[NSArray arrayWithObjects:@"", mapSection, nil] forKeys:_dKeys];
    [_editableFieldsWithSectionTitles insertObject:mapSectionDict atIndex:0];

    // Create and add a read only map cell.
    OTMMapDetailCellRenderer *readOnlyMapDetailCellRenderer = [[OTMMapDetailCellRenderer alloc] init];
    readOnlyMapDetailCellRenderer.cellHeight = 120;

    // Add the read only map cell to the standard fields data structure.
    NSArray *readOnlyMapSection = [NSArray arrayWithObject:readOnlyMapDetailCellRenderer];
    mapSectionDict = [[NSDictionary alloc] initWithObjects:[NSArray arrayWithObjects:@"", readOnlyMapSection, nil] forKeys:_dKeys];
    [_fieldsWithSectionTitles insertObject:mapSectionDict atIndex:0];


    // If the photo field is writable display a cell with a callback otherwise
    // the callback does nothing. Same thing for the speices cell.
    OTMStaticClickCellRenderer *speciesRow = nil;
    OTMDetailCellRenderer *pictureRow = nil;
    if ([[OTMEnvironment sharedEnvironment] speciesFieldIsWritable]) {
        speciesRow = [[OTMStaticClickCellRenderer alloc] initWithKey:@"tree.species_name"
                                                       clickCallback:^(OTMDetailCellRenderer *renderer, NSMutableDictionary *cellData)
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
        speciesRow.defaultName = [@"Set Species" stringByAppendingFormat:@" (%@)", spName];
        speciesRow.detailDataKey = @"tree.sci_name";
    } else {
        speciesRow = [[OTMStaticClickCellRenderer alloc] initWithKey:@"tree.species_name"
                                                       clickCallback:^(OTMDetailCellRenderer *renderer, NSMutableDictionary *cellData) {}];

        speciesRow.defaultName = @"Species cannot be changed";
        speciesRow.detailDataKey = @"tree.sci_name";
    }

    if ([[OTMEnvironment sharedEnvironment] canAddTreePhoto]) {
        pictureRow = [[OTMStaticClickCellRenderer alloc]
                      initWithName:@"Tree Picture"
                               key:@""
                     clickCallback:^(OTMDetailCellRenderer *renderer, NSMutableDictionary *cellData)
        {
            [self updatePicture];
        }];
    } else {
        pictureRow = [[OTMStaticClickCellRenderer alloc]
                      initWithName:@"Picture cannot be changed"
                               key:@""
                     clickCallback:^(OTMDetailCellRenderer *renderer, NSMutableDictionary *cellData) {}];
    }

    // Species and photo cells get added to the structure for editable fields.
    NSArray *speciesAndPicSection = [NSArray arrayWithObjects:speciesRow, pictureRow, nil];
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
            NSDictionary *editSectionDict = [[NSDictionary alloc] initWithObjects:[NSArray arrayWithObjects:title, editCells, nil] forKeys:_dKeys];
            [_editableFieldsWithSectionTitles addObject:editSectionDict];
        }
    }

    // Set the inited property on all the editable cells.
    for (NSDictionary *dict in _editableFieldsWithSectionTitles) {
        for (OTMEditDetailCellRenderer *cell in [dict valueForKey:@"cells"]) {
            cell.inited = NO;
        }
    }

    self.navigationItem.rightBarButtonItem.enabled = [self canEditBothPlotAndTree];
    curFields = _fieldsWithSectionTitles;

    /**
     * We have now set the fields that need to be rendered but we also need to
     * create an array of cells that are set up with values. Each cell
     * represents a type not an actual individual cell. The data may have
     * multiple values for a field of a certain type. For example a tree may
     * have "Tree Tender" -> "Alice", "Bob", "Carol"
     * Each should be displayed in a cell.
     */
    [self updateCurrentCells];
}

- (void)updateCurrentCells
{
    NSMutableArray *cellsWithSectionTitles = [[NSMutableArray alloc] init];

    for (id section in curFields) {
        NSString  *sect = [section objectForKey:@"title"];
        NSArray *fields = [section objectForKey:@"cells"];
        NSMutableArray *sectionCells = [[NSMutableArray alloc] init];

        for (OTMDetailCellRenderer *field in fields) {
            NSArray *cells = [field prepareAllCells:self.data inTable:self.tableView withOriginatingDelegate:self.navigationController];
            [sectionCells addObjectsFromArray:cells];
        }

        // First remove all cells that have a sort key.
        NSMutableIndexSet *indexSet = [[NSMutableIndexSet alloc] init];
        NSMutableArray *sortableCells = [[NSMutableArray alloc] init];
        NSMutableSet *sortKeySet = [[NSMutableSet alloc] init];
        for (int i = 0; i < [sectionCells count]; i++) {
            if ([[sectionCells objectAtIndex:i] sortKey] != nil) {
                [indexSet addIndex:i];
                [sortKeySet addObject:[[sectionCells objectAtIndex:i] sortKey]];
                [sortableCells addObject:[sectionCells objectAtIndex:i]];
            }
        }
        if (indexSet) {
            [sectionCells removeObjectsAtIndexes:indexSet];
        }

        // Now sort the cells that are sortable first by key and then by data so
        // they are grouped together.
        NSSortDescriptor *dataSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"sortData" ascending:NO];
        NSSortDescriptor *keySortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"sortKey" ascending:YES];
        NSArray *sortDescriptors = [NSArray arrayWithObjects:keySortDescriptor, dataSortDescriptor, nil];

        // Build an array of cells first with non-sortable and then append the
        // sortable cells.
        NSMutableArray *cellsToReturn = [[NSMutableArray alloc] init];
        NSArray *sortedCells = [sortableCells sortedArrayUsingDescriptors:sortDescriptors];
        [cellsToReturn addObjectsFromArray:[sectionCells copy]];

        // Add the load more cell to sortable sections with more than three
        // items. We are going to assume that all the sorted cells for a section
        // will only have a single load more button.
        if ([sortedCells count] > 3 && !editMode) {
            OTMLoadMoreCell *loadMoreCell = [[OTMLoadMoreCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:[OTMLoadMoreCell reuseIdentifier]];
            NSRange headRange = NSMakeRange(0, 3);
            NSRange tailRange = NSMakeRange(3, [sortedCells count] - 3);

            NSMutableArray *cellsToHide = [[sortedCells subarrayWithRange:tailRange] mutableCopy];

            sortedCells = [sortedCells subarrayWithRange:headRange];

            loadMoreCell.hiddenCells = cellsToHide;
            UIButton *button = [[UIButton alloc] init];
            [button addTarget:self action:@selector(loadMoreCells:) forControlEvents:UIControlEventTouchDown];
            [button setTitle:@"Load More..." forState:UIControlStateNormal];
            [button setTitleColor:[[OTMEnvironment sharedEnvironment] primaryColor] forState:UIControlStateNormal];
            // Make the button fill the cell so you can't miss it.
            button.frame = CGRectMake(0, 0, loadMoreCell.frame.size.width, loadMoreCell.frame.size.height);

            [loadMoreCell addSubview:button];

            OTMCellSorter *loadMore = [[OTMCellSorter alloc] initWithCell:loadMoreCell
                                                                  sortKey:nil
                                                                 sortData:@""
                                                                   height:loadMoreCell.frame.size.height
                                                            clickCallback:nil];

            [cellsToReturn addObjectsFromArray:sortedCells];
            [cellsToReturn addObject:loadMore];
        } else {
            [cellsToReturn addObjectsFromArray:sortedCells];
        }

        NSDictionary *preparedCellsForSection =
            [[NSDictionary alloc] initWithObjects:[[NSArray alloc] initWithObjects:sect, cellsToReturn, nil]
                                          forKeys:_dKeys];

        [cellsWithSectionTitles addObject:preparedCellsForSection];
    }

    // If there are no cells in a section in non-edit mode then add a cell that
    // Explains that there are no items of that type listed.
    for (int i =0; i < [cellsWithSectionTitles count]; i++) {
        NSDictionary *cellSection = cellsWithSectionTitles[i];
        NSArray *sectionCells = [cellSection objectForKey:@"cells"];
        if ([sectionCells count] == 0) {
            UITableViewCell *noDataMessageCell = [[UITableViewCell alloc] init];
            NSString *titleString = [[cellSection objectForKey:@"title"] lowercaseString];
            // "Stewardship" should show as "stewardship actions" for the user.
            if ([titleString isEqualToString:@"stewardship"]) {
                titleString = @"stewardship actions";
            }
            noDataMessageCell.textLabel.text = [NSString stringWithFormat:@"No %@ listed", titleString];
            OTMCellSorter *noDataMessageCellSorter = [[OTMCellSorter alloc] initWithCell:noDataMessageCell
                                                                                sortKey:nil
                                                                               sortData:@""
                                                                                 height:noDataMessageCell.frame.size.height
                                                                          clickCallback:nil];
            NSDictionary *noDataMessageDict = @{
                                                @"title" : [cellSection objectForKey:@"title"],
                                                @"cells" : [[NSArray alloc] initWithObjects:noDataMessageCellSorter, nil]
                                                };
            [cellsWithSectionTitles removeObjectAtIndex:i];
            [cellsWithSectionTitles insertObject:noDataMessageDict atIndex:i];
        }
    }
    curCells = cellsWithSectionTitles;
}

- (void)loadMoreCells:(id)sender
{
    UIButton *senderButton = (UIButton *)sender;
    UITableViewCell *buttonCell = (UITableViewCell *)[senderButton superview];
    OTMLoadMoreCell *cell = (OTMLoadMoreCell *)[buttonCell superview];

    NSInteger numberOfCellsToLoad = [cell.hiddenCells count] >= 3 ? 3 : [cell.hiddenCells count];

    NSRange range = NSMakeRange(0, numberOfCellsToLoad);
    NSArray *cellsToAdd = [cell.hiddenCells subarrayWithRange:range];
    [cell.hiddenCells removeObjectsInRange:range];
    NSIndexPath *path = [self.tableView indexPathForCell:cell];
    NSInteger startRow = path.row;

    NSMutableArray *paths = [[NSMutableArray alloc] init];
    for (int i = 0; i < numberOfCellsToLoad; i++) {
        [paths addObject:[NSIndexPath indexPathForRow:startRow + (NSInteger)i inSection:path.section]];
    }
    NSMutableDictionary *updateDict = [[curCells objectAtIndex:path.section] mutableCopy];
    NSMutableArray *newCells = [[updateDict objectForKey:@"cells"] mutableCopy];
    OTMCellSorter *loadMore = [newCells lastObject];
    [newCells removeLastObject];
    [newCells addObjectsFromArray:cellsToAdd];

    // Remove load more button if there aren't more cells.
    if ([cell.hiddenCells count] > 0) {
        [newCells addObject:loadMore];
    }

    [updateDict setObject:newCells forKey:@"cells"];

    NSMutableArray *mutableCurrentCells = [curCells mutableCopy];
    [mutableCurrentCells removeObjectAtIndex:path.section];
    [mutableCurrentCells insertObject:[updateDict copy] atIndex:path.section];
    curCells = [mutableCurrentCells copy];

    // Update the table with animation.
    [tableView beginUpdates];

    // If there are no more cells, remove the load more button from the table.
    if ([cell.hiddenCells count] == 0) {
        [[self tableView]
            deleteRowsAtIndexPaths:[NSArray arrayWithObject:path]
                  withRowAnimation:UITableViewRowAnimationBottom];
    }

    [[self tableView]
        insertRowsAtIndexPaths:paths
              withRowAnimation:UITableViewRowAnimationTop];
    [tableView endUpdates];
}

- (void)setEcoKeys:(NSArray *)ecoKeys
{
    for (int i = 0; i < [ecoKeys count]; i++) {
        NSMutableArray *ecoFieldRenderers = [[NSMutableArray alloc] init];
        NSArray *ecoFields = [ecoKeys objectAtIndex:i];
        for (int j = 0; j < [ecoFields count]; j++) {
            [ecoFieldRenderers addObject:[ecoFields objectAtIndex:j]];
        }
        NSDictionary *ecoSectionDict = [[NSDictionary alloc] initWithObjects:[NSArray arrayWithObjects:@"Ecosystem benefits", ecoFieldRenderers, nil] forKeys:_dKeys];
        [_fieldsWithSectionTitles addObject:ecoSectionDict];
        curFields = _fieldsWithSectionTitles;
        [self updateCurrentCells];
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

- (NSString *)messageFromValidationErrorResponse:(NSString *)body error:(NSError *)error {
    NSData *bodyData = [body dataUsingEncoding:NSUTF8StringEncoding];
    id json = [NSJSONSerialization JSONObjectWithData:bodyData
                                              options:0
                                                error:&error];
    if (error) {
        return nil;
    }
    NSArray *globals = [json objectForKey:@"globalErrors"];
    NSDictionary *fields = [json objectForKey:@"fieldErrors"];
    // We have limited space in a UIAlertView, so we show just the first global message
    // and the first field validation message
    NSString *fieldMessage = @"";
    NSString *globalMessage = @"One or more field values is invalid.";
    if ([[fields allValues] count] > 0) {
        NSString *trimmed = [[[[fields allValues] objectAtIndex:0] objectAtIndex:0]
                             stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        fieldMessage = [NSString stringWithFormat: @"\n\n%@", trimmed];
    }
    if ([globals count] > 0) {
        globalMessage = [[globals objectAtIndex:0]
                         stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }
    return [NSString stringWithFormat: @"%@%@", globalMessage, fieldMessage];
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
        [self updateCurrentCells];
        [self.tableView reloadData];
    } else {
        if (saveChanges) {
            for (NSArray *section in _editableFieldsWithSectionTitles) {
                for(OTMEditDetailCellRenderer *editFld in [section valueForKey:@"cells"]) {
                    self.data = [editFld updateDictWithValueFromCell:data];
                }
            }
            // Clean up temp keys from udf data.
            //NSMutableSet *udfCollectionStrings = [[NSMutableSet alloc] init];
            for (NSArray *set in [[OTMEnvironment sharedEnvironment] fieldKeys]) {
                for (id cellRenderer in set) {
                    if ([cellRenderer isKindOfClass:[OTMCollectionUDFCellRenderer class]]) {
                        NSArray *dataPath = [[cellRenderer dataKey] componentsSeparatedByString:@"."];
                        if ([dataPath count] >= 2) {
                            NSMutableArray *udfCollection = [[self.data objectForKey:dataPath[0]] objectForKey:dataPath[1]];
                            //NSMutableArray *cleanedUdfData = [[NSMutableArray alloc] init];
                            for (int i = 0; i < [udfCollection count]; i++) {
                                NSDictionary *udfData = udfCollection[i];
                                NSMutableDictionary *cleanedUdf = [udfData mutableCopy];
                                [cleanedUdf removeObjectForKey:@"tempId"];
                                [udfCollection removeObjectAtIndex:i];
                                [udfCollection insertObject:cleanedUdf atIndex:i];
                            }
                        }
                    }
                }
            }
        }

        [self syncTopData];
        curFields = _fieldsWithSectionTitles;
        [self updateCurrentCells];
        [self.tableView reloadData];

        if (saveChanges) {
            OTMLoginManager* loginManager = [SharedAppDelegate loginManager];
            OTMUser *user = loginManager.loggedInUser;
            NSMutableDictionary *writableData = [self getWritableFieldData];

            if (self.data[@"plot"][@"id"] == nil) {
                // No 'id' parameter indicates that this is a new plot/tree
                NSLog(@"Sending new tree data:\n%@", data);

                [[AZWaitingOverlayController sharedController] showOverlayWithTitle:@"Saving"];

                NSArray *pendingImageData = [self stripPendingImageData];
                [[[OTMEnvironment sharedEnvironment] api] addPlotWithOptionalTree:writableData user:user
                                                                         callback:^(id json, NSError *err){

                    [[AZWaitingOverlayController sharedController] hideOverlay];

                    if (err == nil) {
                        data = [json mutableDeepCopy];
                        [[OTMEnvironment sharedEnvironment] setGeoRev:data[@"geoRevHash"]];
                        [self pushImageData:pendingImageData newTree:YES];
                    } else {
                        NSLog(@"Error adding tree: %@", err);

                        if ([[[err userInfo] objectForKey:@"statusCode"] integerValue] == 400) {
                            NSError *jsonParseErr;
                            NSString *message = [self messageFromValidationErrorResponse:[[err userInfo] objectForKey:@"body"] error:jsonParseErr];
                            if (!jsonParseErr) {
                                [[[UIAlertView alloc] initWithTitle:nil
                                                            message:message
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil] show];
                            }
                        } else {
                            [[[UIAlertView alloc] initWithTitle:nil
                                                        message:@"Sorry. There was a problem saving the new tree."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil] show];
                        }
                    }
                }];
            } else {
                NSLog(@"Updating existing plot/tree data:\n%@", data);

                [[AZWaitingOverlayController sharedController] showOverlayWithTitle:@"Saving"];

                NSArray *pendingImageData = [self stripPendingImageData];
                [[[OTMEnvironment sharedEnvironment] api] updatePlotAndTree:writableData user:user callback:^(id json, NSError *err){

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
                        if ([[[err userInfo] objectForKey:@"statusCode"] integerValue] == 400) {
                            NSError *jsonParseErr;
                            NSString *message = [self messageFromValidationErrorResponse:[[err userInfo] objectForKey:@"body"] error:jsonParseErr];
                            if (!jsonParseErr) {
                                [[[UIAlertView alloc] initWithTitle:nil
                                                            message:message
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil] show];
                            }
                        } else {
                            [[[UIAlertView alloc] initWithTitle:nil
                                                        message:@"Sorry. There was a problem saving the updated tree details."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil] show];
                        }
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

- (NSMutableDictionary *)getWritableFieldData {
    NSMutableDictionary *writableData = [[NSMutableDictionary alloc] init];
    NSDictionary *fieldData = [[OTMEnvironment sharedEnvironment] fieldData];

    for (NSString *model in @[@"plot", @"tree"]) {
        NSDictionary *modelData = self.data[model];
    
        if (modelData != nil) {
            NSMutableDictionary *writableModelData = [[NSMutableDictionary alloc] init];
        
            for (NSString *key in modelData) {
                NSString *fieldKey = [NSString stringWithFormat:@"%@.%@", model, key];
                NSDictionary *field = fieldData[fieldKey];
            
                if (field != nil && ([key isEqualToString:@"id"] || [field[@"can_write"] boolValue])) {
                    writableModelData[key] = modelData[key];
                }
            }
            writableData[model] = writableModelData;
        }
    }
    return writableData;
}

- (void)addNewUdf:(NSNotification *)notification
{
    NSDictionary *notificationData = (NSDictionary *)[notification object];
    NSString *key = [notificationData objectForKey:@"key"];
    NSString *field = [notificationData objectForKey:@"field"];

    // Increment the temp key.
    tempId++;
    NSNumber *tId = [NSNumber numberWithInt:tempId];
    [[notificationData objectForKey:@"data"] setObject:tId forKey:@"tempId"];

    NSMutableArray *udf = [[self.data objectForKey:key] objectForKey:field];
    if (!udf) {
        [[self.data objectForKey:key] setValue:[[NSMutableArray alloc] init] forKey:field];
        udf = [[self.data objectForKey:key] objectForKey:field];
    }

    /**
     * For this to be set as a new tree and not just an empty planting site, we
     * need to set a null value on a tree field. Diameter works fine though is
     * an arbitrary dicision. If there is not a diamter set for the tree, we set
     * it to null. This will allow a new tree to be created for our new UDF data
     * to be added to.
     *
     * @TODO - this is a but in the API and will eventually be fixed. We should
     * fix it here when that happens.
     */
    if ([key isEqualToString:@"tree"]) {
        id diameter = [[self.data objectForKey:key] objectForKey:@"diameter"];
        if (!diameter) {
            [[self.data objectForKey:key] setObject:[NSNull alloc] forKey:@"diameter"];
        }
    }

    // Now add the new data to the tree data object and reload the view.
    [udf addObject:[notificationData objectForKey:@"data"]];
    [self updateCurrentCells];
    [self.tableView reloadData];
}

- (void)updateUdf:(NSNotification *)notification
{
    NSDictionary *notificationData = (NSDictionary *)[notification object];
    NSString *key = [notificationData objectForKey:@"key"];
    NSString *field = [notificationData objectForKey:@"field"];

    // Ufd feild must be there or they couldn't have clicked it.
    NSMutableArray *udfs = [[self.data objectForKey:key] objectForKey:field];
    for (int i = 0; i < [udfs count]; i++) {
        NSDictionary *oldUdf = [udfs objectAtIndex:i];
        if ([oldUdf objectForKey:@"id"] != nil && [oldUdf objectForKey:@"id"] == [[notificationData objectForKey:@"data"] objectForKey:@"id"]) {
            [udfs removeObjectAtIndex:i];
            [udfs insertObject:[notificationData objectForKey:@"data"]atIndex:i];
        }
        // Check for tempId as well.
        if ([oldUdf objectForKey:@"tempId"] != nil && [oldUdf objectForKey:@"tempId"] == [[notificationData objectForKey:@"data"] objectForKey:@"tempId"]) {
            [udfs removeObjectAtIndex:i];
            [udfs insertObject:[notificationData objectForKey:@"data"]atIndex:i];
        }
    }

    [self updateCurrentCells];
    [self.tableView reloadData];
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
            // The view controller uses the presence of this property to
            // determine how to display the value, so it must be nil'd out if it
            // is not a choices field.
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
    [self updateSpeciesEditCellWithString:newSpeciesCommonName];

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

    // Loop through all the current cells until the species_name data key is
    // found. If it is update the label and return the indexpath.
    for (int i = 0; i < [curFields count]; i++) {
        for (int j = 0; j < [[[curFields objectAtIndex:i] valueForKey:@"cells"] count]; j++) {
            OTMStaticClickCellRenderer *cell = [[[curFields objectAtIndex:i] valueForKey:@"cells"] objectAtIndex:j];
            if ([[cell dataKey] isEqualToString:@"tree.species_name"]) {
                cell.detailcell.textLabel.text = label;
            }
        }
    }
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
    return [curCells count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[curCells objectAtIndex:section] valueForKey:@"cells"] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [[curCells objectAtIndex:section] valueForKey:@"title"];

}

- (void)tableView:(UITableView *)tblView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OTMCellSorter *holder = [[[curCells objectAtIndex:indexPath.section] valueForKey:@"cells"] objectAtIndex:indexPath.row];
    if (editMode) {
        Function2v clicker = [holder clickCallback];
        if (clicker) {
            NSMutableDictionary *startData = [holder originalData];
            clicker(self, startData);
        }
    } else {
        if ([[tblView cellForRowAtIndexPath:indexPath] accessoryType] != UITableViewCellAccessoryNone)
        [self performSegueWithIdentifier:@"fieldDetail" sender:indexPath];
    }

    [tblView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tblView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OTMCellSorter *holder = [[[curCells objectAtIndex:indexPath.section] valueForKey:@"cells"] objectAtIndex:indexPath.row];
    return holder.cellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tblView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OTMCellSorter *holder = [[[curCells objectAtIndex:indexPath.section] valueForKey:@"cells"] objectAtIndex:indexPath.row];
    UITableViewCell *cell = [holder cell];
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
    return [self canEditThing:@"plot"] || [self canEditThing:@"tree"];
}

- (BOOL)canEditBothPlotAndTree
{
    return [self canEditThing:@"plot"] && [self canEditThing:@"tree"];
}

- (BOOL)cannotDeletePlotOrTree
{
    return !([self canDeletePlot] || [self canDeleteTree]);
}

- (BOOL)shouldNotShowDeleteButtonsInFooterForSection:(NSInteger)section
                                         ofTableView:(UITableView *)aTableView
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
    // @see theightForHeaderInSection for explanation for 0.01f.
    if (editMode && ([self numberOfSectionsInTableView:aTableView] - 1) == section) {
        return [self footerHeight];
    } else {
        // @see theightForHeaderInSection for explanation for 0.01f.
        return 0.01f;
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
