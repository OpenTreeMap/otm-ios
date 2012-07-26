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

#import "OTMFieldDetailViewController.h"
#import "OTMView.h"
#import "OTMFormatters.h"
#import "OTMEnvironment.h"
#import "AZWaitingOverlayController.h"
#import "AZMapHelper.h"
#import "OTMMapTableViewCell.h"

@interface OTMFieldDetailViewController (Private)

- (NSString *)pendingValueAtIndex:(NSInteger)index;
- (NSString *)pendingEditDescriptionAtIndex:(NSInteger)index;
- (NSInteger)numberOfPendingEdits;

@end

@implementation OTMFieldDetailViewController

@synthesize data, fieldKey, ownerFieldKey, fieldName, fieldFormatString, choices, pendingEditsUpdatedCallback;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (BOOL)isGeomField {
    return [self.fieldKey isEqualToString:@"geometry"];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.backgroundView = [[OTMView alloc] init];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationItem.title = self.fieldName;
    [self.tableView reloadData];
    [self clearSelection];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Geometry field keys use 1 second per edit
    if ([self isGeomField]) {
        return [self numberOfPendingEdits] + 1;
    } else { // Otherwise, we have a top section
             // for the original, and a bottom section
             // for all the rest
        return 2;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0 || [self isGeomField]) {
        // The top section has a single cell with the current value
        return 1;
    } else {
        return [self numberOfPendingEdits];
    }
}

- (NSInteger)numberOfPendingEdits
{
    NSDictionary *pendingEditsDict = [self.data objectForKey:@"pending_edits"];
    if (pendingEditsDict) {
        NSDictionary *editsDict = [pendingEditsDict objectForKey:self.fieldKey];
        if (!editsDict) {
            editsDict = [pendingEditsDict objectForKey:self.ownerFieldKey];
        }
        return [[editsDict objectForKey:@"pending_edits"] count];
    } else {
        return 0;
    }
}

- (id)pendingValueAtIndex:(NSInteger)index
{
    bool thisFieldsValueIsControlledByAnotherField = NO;
    NSDictionary *editsDict = [[self.data objectForKey:@"pending_edits"] objectForKey:self.fieldKey];
    if (!editsDict) {
        editsDict = [[self.data objectForKey:@"pending_edits"] objectForKey:self.ownerFieldKey];
        thisFieldsValueIsControlledByAnotherField = YES;
    }

    NSDictionary *editDict = [[editsDict objectForKey:@"pending_edits"] objectAtIndex:index];

    // geometry is a special case. It has a dictionary value rather than a plain string.
    // There is no need to check for related fields or format the value, so the rest of
    // the method can be skipped.
    if ([self isGeomField]) {
        return [editDict objectForKey:@"value"];
    }

    NSString *rawValueString;
    if (thisFieldsValueIsControlledByAnotherField) {
        rawValueString = [[editDict objectForKey:@"related_fields"] objectForKey:self.fieldKey];
    } else {
        rawValueString = [editDict objectForKey:@"value"];
    }

    NSString *valueString;
    if (choices) {
        for(NSDictionary *choice in choices) {
            if ([rawValueString isEqualToString:[[choice objectForKey:@"key"] description]]) {
                valueString = [choice objectForKey:@"value"];
            }
        }
    } else {
        if (thisFieldsValueIsControlledByAnotherField) {
            valueString = rawValueString;
        } else {
            valueString = [OTMFormatters fmtObject:rawValueString withKey:fieldFormatString];
        }
    }
    return valueString;
}

- (NSString *)pendingEditDescriptionAtIndex:(NSInteger)index
{
    NSDictionary *editsDict = [[self.data objectForKey:@"pending_edits"] objectForKey:self.fieldKey];
    if (!editsDict) {
        editsDict = [[self.data objectForKey:@"pending_edits"] objectForKey:self.ownerFieldKey];
    }
    NSDictionary *editDict = [[editsDict objectForKey:@"pending_edits"] objectAtIndex:index];
    NSString *dateString = [OTMFormatters fmtOtmApiDateString:[editDict objectForKey:@"submitted"]];
    if (dateString) {
        return [NSString stringWithFormat:@"%@ on %@", [editDict objectForKey:@"username"], dateString];
    } else {
        return nil;
    }
}

#define kFieldDetailCurrentValueCellIdentifier @"kFieldDetailCurrentValueCellIdentifier"
#define kFieldDetailPendingEditCellIdentifier @"kFieldDetailPendingEditCellIdentifier"
#define kFieldDetailPendingLocationEditCellIdentifier @"kFieldDetailPendingLocationEditCellIdentifier"

- (UITableViewCell *)buildMapCellWithDictionary:(NSDictionary *)dict forTableView:(UITableView *)tableView
{
    CLLocationCoordinate2D coordinate = [AZMapHelper CLLocationCoordinate2DMakeWithDictionary:dict];
    return [self buildMapCellWithCoordinate:coordinate forTableView:tableView];
}

- (UITableViewCell *)buildMapCellWithCoordinate:(CLLocationCoordinate2D)coordinate forTableView:(UITableView *)tableView
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"kOTMMapDetailCellRendererTableCellId"];

    if (cell == nil) {
        cell = [[OTMMapTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"kOTMMapDetailCellRendererTableCellId"];
    }

    [(OTMMapTableViewCell *)cell annotateCenter:coordinate];

    cell.contentView.frame = CGRectOffset(cell.frame, 10, 10);

    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;

    if (indexPath.section == 0) {
        if ([self isGeomField])
        {
            cell = [self buildMapCellWithDictionary:[self.data objectForKey:self.fieldKey] forTableView:tableView];
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:kFieldDetailCurrentValueCellIdentifier];
            NSString *rawValueString = [[self.data decodeKey:self.fieldKey] description];
            NSString *valueString;
            if (choices) {
                for(NSDictionary *choice in choices) {
                    if ([rawValueString isEqualToString:[[choice objectForKey:@"key"] description]]) {
                        valueString = [choice objectForKey:@"value"];
                    }
                }
            } else {
                valueString = [OTMFormatters fmtObject:rawValueString withKey:fieldFormatString];
            }
            if (valueString && valueString != @"") {
                cell.textLabel.text = valueString;
            } else {
                cell.textLabel.text = @"No Value";
            }
            if ([[[SharedAppDelegate loginManager] loggedInUser] canApproveOrRejectPendingEdits]) {
                cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            } else {
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
        }
    } else {
        if ([self isGeomField])
        {
            cell = [self buildMapCellWithDictionary:(NSDictionary *)[self pendingValueAtIndex:(indexPath.section - 1)]  forTableView:tableView];
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:kFieldDetailPendingEditCellIdentifier];
            cell.textLabel.text = [self pendingValueAtIndex:indexPath.row];
            cell.detailTextLabel.text = [self pendingEditDescriptionAtIndex:indexPath.row];
            if ([[[SharedAppDelegate loginManager] loggedInUser] canApproveOrRejectPendingEdits]) {
                cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            } else {
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
        }
    }

    if ([[[SharedAppDelegate loginManager] loggedInUser] canApproveOrRejectPendingEdits]) {
        [self styleCell:cell asStatus:nil];
    }

    return cell;
}

- (void)styleCell:(UITableViewCell *)cell asStatus:(NSString *)status
{
    NSString *imageName;
    if ([[[SharedAppDelegate loginManager] loggedInUser] canApproveOrRejectPendingEdits])
    {
        if ([status isEqualToString:@"approved"]) {
            imageName = @"pending-approved";
        } else if ([status isEqualToString:@"rejected"]) {
            imageName = nil;
        } else {
            imageName = @"pending-unapproved";
        }
    } else {
        // No accessory image is displayed if the user cannot approve pending edits
        imageName = nil;
    }
    cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
}

- (void)clearSelection
{
    for (int section = 0; section < [self.tableView numberOfSections]; section++) {
        for (int row = 0; row < [self.tableView numberOfRowsInSection:section]; row++) {
            NSIndexPath* cellPath = [NSIndexPath indexPathForRow:row inSection:section];
            UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:cellPath];
            [self styleCell:cell asStatus:nil];
            [self.tableView deselectRowAtIndexPath:cellPath animated:NO];
        }
    }
    selectedCell = nil;
    [self.navigationItem setRightBarButtonItem:nil animated:NO];

    [self.navigationItem setLeftBarButtonItem:nil animated:NO];
}

- (void)tableView:(UITableView *)tableView approveCellAtPath:(NSIndexPath *)indexPath
{
    for (int section = 0; section < [tableView numberOfSections]; section++) {
        for (int row = 0; row < [tableView numberOfRowsInSection:section]; row++) {
            NSIndexPath* cellPath = [NSIndexPath indexPathForRow:row inSection:section];
            UITableViewCell* cell = [tableView cellForRowAtIndexPath:cellPath];
            if ([cellPath compare:indexPath] == NSOrderedSame) {
                [self styleCell:cell asStatus:@"approved"];
             } else {
                [self styleCell:cell asStatus:@"rejected"];
             }
        }
    }

    if (!selectedCell) {
        [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(confirmSelection:)] animated:NO];

        [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelPendingSelection:)] animated:NO];

        selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    }
}

- (BOOL)currentValueIsSelected
{
    return selectedCell && ([[self.tableView indexPathForSelectedRow] section] == 0);
}

- (void)confirmSelection:(id)sender
{
    if (self.currentValueIsSelected) {
        [[AZWaitingOverlayController sharedController] showOverlayWithTitle:@"Saving"];
        [self rejectNextEdit];
    } else {
        [self approveSelectedPendingEdit];
    }
}

- (void)cancelPendingSelection:(id)sender
{
    [self clearSelection];
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 0) {
        return @"Current Value";
    } else if (section == 1) {
        return @"Pending Edits";
    } else {
        return nil;
    }
}

- (CGFloat)tableView:(UITableView *)tblView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self isGeomField]) {
        return 120.0;
    } else {
        return 44.0;
    }
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[[SharedAppDelegate loginManager] loggedInUser] canApproveOrRejectPendingEdits]) {
        [self tableView:tableView approveCellAtPath:indexPath];
    }
}

- (void)approveSelectedPendingEdit
{
    NSInteger index = [[self.tableView indexPathForSelectedRow] row];

    NSDictionary *editsDict = [[self.data objectForKey:@"pending_edits"] objectForKey:self.fieldKey];
    if (!editsDict) {
        editsDict = [[self.data objectForKey:@"pending_edits"] objectForKey:self.ownerFieldKey];
    }
    NSDictionary *editDict = [[editsDict objectForKey:@"pending_edits"] objectAtIndex:index];

    NSInteger pendingEditId = [[editDict objectForKey:@"id"] intValue];

    OTMUser *user = [[SharedAppDelegate loginManager] loggedInUser];

    [[AZWaitingOverlayController sharedController] showOverlayWithTitle:@"Approving"];

    [[[OTMEnvironment sharedEnvironment] api] approvePendingEdit:pendingEditId user:user callback:^(id json, NSError *error) {

        [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];

        if (!error) {
            [[AZWaitingOverlayController sharedController] hideOverlay];
            self.data = [json mutableDeepCopy];
            if (pendingEditsUpdatedCallback) {
                pendingEditsUpdatedCallback(self.data);
            }
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            [[AZWaitingOverlayController sharedController] hideOverlay];
            NSLog(@"Error approving pending edit: %@", [error description]);
            [UIAlertView showAlertWithTitle:nil message:@"There was a problem approving the pending edit." cancelButtonTitle:@"OK"otherButtonTitle:nil callback:nil];

        }
    }];
}

#pragma mark - UIActionSheet delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([action isEqualToString:@"approve"])
    {
        if (buttonIndex == 0) {
            [self approveSelectedPendingEdit];
        } else {
            [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
        }
    } else if ([action isEqualToString:@"reject"]) {
        if (buttonIndex == 0)
        {
            [[AZWaitingOverlayController sharedController] showOverlayWithTitle:@"Rejecting"];
            [self rejectNextEdit];
        }
    }
}

- (void)beginRejectAllEdits:(id)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Do you want to reject all the pending edits for this field?"
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:@"Reject"
                                                    otherButtonTitles:nil];
        action = @"reject";
    [actionSheet showFromTabBar:self.navigationController.tabBarController.tabBar];
}

- (void)rejectNextEdit
{
    NSDictionary *editsDict = [[self.data objectForKey:@"pending_edits"] objectForKey:self.fieldKey];
    if (!editsDict) {
        editsDict = [[self.data objectForKey:@"pending_edits"] objectForKey:self.ownerFieldKey];
    }
    NSDictionary *editDict = [[editsDict objectForKey:@"pending_edits"] objectAtIndex:0];
    if (editDict) {
        NSInteger pendingEditId = [[editDict objectForKey:@"id"] intValue];
        OTMUser *user = [[SharedAppDelegate loginManager] loggedInUser];
        [[[OTMEnvironment sharedEnvironment] api] rejectPendingEdit:pendingEditId user:user callback:^(id json, NSError *error) {

            if (!error) {
                self.data = [json mutableDeepCopy];
                [self rejectNextEdit];
            } else {
                [[AZWaitingOverlayController sharedController] hideOverlay];
                NSLog(@"Error rejecting pending edit: %@", [error description]);
                [UIAlertView showAlertWithTitle:nil message:@"There was a problem rejecting a pending edit." cancelButtonTitle:@"OK"otherButtonTitle:nil callback:nil];
            }
        }];
    } else {
        [[AZWaitingOverlayController sharedController] hideOverlay];
        if (pendingEditsUpdatedCallback) {
            pendingEditsUpdatedCallback(self.data);
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}


@end
