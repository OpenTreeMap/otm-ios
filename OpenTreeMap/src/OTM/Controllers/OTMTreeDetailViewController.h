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

#import <UIKit/UIKit.h>
#import "OTMScrollAwareViewController.h"
#import "OTMDetailTableViewCell.h"
#import "OTMPictureTaker.h"
#import "OTMMapDetailCellRenderer.h"

@class OTMTreeDetailViewController; // declared early so the delegate can use the type in its declaration

@protocol OTMTreeDetailViewDelegate <NSObject>
@required
- (void)viewController:(OTMTreeDetailViewController *)viewController addedTree:(NSDictionary *)details;
- (void)viewController:(OTMTreeDetailViewController *)viewController addedTree:(NSDictionary *)details withPhoto:(UIImage *)photo;

- (void)viewController:(OTMTreeDetailViewController *)viewController editedTree:(NSDictionary *)details withOriginalLocation:(CLLocationCoordinate2D)coordinate originalData:(NSDictionary *)originalData;
- (void)viewController:(OTMTreeDetailViewController *)viewController editedTree:(NSDictionary *)details withOriginalLocation:(CLLocationCoordinate2D)coordinate originalData:(NSDictionary *)originalData withPhoto:(UIImage *)photo;

- (void)treeAddCanceledByViewController:(OTMTreeDetailViewController *)viewController;

- (void)plotDeletedByViewController:(OTMTreeDetailViewController *)viewController;
@end

@interface OTMTreeDetailViewController : OTMScrollAwareViewController<UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIActionSheetDelegate> {
    BOOL editMode;
    BOOL updated;
    NSMutableDictionary *data;
    
    NSArray *txToEditRemove;
    NSArray *txToEditReload;
    
    NSArray *editFields;
    NSMutableArray *allFields;
    
    NSArray *curFields;
    NSArray *allKeys;

    NSString *deleteType;
}

@property (nonatomic,weak) id<OTMTreeDetailViewDelegate> delegate;

@property (nonatomic,strong) IBOutlet OTMPictureTaker *pictureTaker;

@property (nonatomic,strong) IBOutlet UITableView *tableView;
@property (nonatomic,strong) IBOutlet UILabel* address;
@property (nonatomic,strong) IBOutlet UILabel* species;
@property (nonatomic,strong) IBOutlet UILabel* lastUpdateDate;
@property (nonatomic,strong) IBOutlet UILabel* updateUser;
@property (nonatomic,strong) IBOutlet UIImageView* imageView;
@property (nonatomic,strong) IBOutlet UIView* headerView;
@property (nonatomic) CLLocationCoordinate2D originalLocation;
@property (nonatomic) NSDictionary *originalData;

@property (nonatomic,strong) IBOutlet UITableViewCell *acell;

/**
 * Dictionary[String,String] of tree detail key-value pairs
 */
@property (nonatomic, strong) NSDictionary* data;

/**
 * Array[Array[OTMDetailCellRenderer]] keys to display in the main table
 *
 * Each element in the outer array represents a section
 * and each element in the inner array represents a row.
 * 
 * The first row is the title of the section (which can
 * be the empty string)
 */
@property (nonatomic, strong) NSArray* keys;

/**
 * Array[OTMDetailCellRenderer] ecoKeys to display in the main table
 *
 * Each element in the array is a field for displaying a single eco
 * benefit in a table row
 */
@property (nonatomic, strong) NSArray* ecoKeys;

- (IBAction)showTreePhotoFullscreen:(id)sender;
- (IBAction)startOrCommitEditing:(id)sender;
- (IBAction)cancelEditing:(id)sender;

@end
