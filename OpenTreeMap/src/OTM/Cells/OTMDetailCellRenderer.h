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

#import <Foundation/Foundation.h>
#import "OTMFormatter.h"
#import "OTMDetailTableViewCell.h"
#import "OTMDBHTableViewCell.h"
#import "OTMBenefitsTableViewCell.h"

#define kOTMDefaultEditDetailRenderer OTMLabelEditDetailCellRenderer

@class OTMEditDetailCellRenderer;

/**
 * Generic interface for rendering cells
 * Note that the OTMEditDetailCellRender is responsible
 * for handling edit mode
 */
@interface OTMDetailCellRenderer : NSObject


/**
 * Key to access data for this cell
 *
 * Examples:
 *  tree.dbh (tree diameter)
 *  id       (plot id)
 */
@property (nonatomic,strong) NSString *dataKey;

/**
 * Key to access data for the second line of this cell.
 * Used primarily for showing the species scientific name
 * beneath the common name.
 *
 * Example:
 *  tree.scientific_name
 */
@property (nonatomic,strong) NSString *detailDataKey;

/**
 * Key to indicate that this field is linked to the
 * value of another field. Used primarily to link
 * the species scientific name field to the species
 * id.
 *
 * Example:
 *  tree.species
 */
@property (nonatomic,strong) NSString *ownerDataKey;

/**
 * Block that takes a single argument (the renderer)
 * and returns a UITableViewCell
 *
 * Default returns table cell with "default" cell styling
 */
@property (nonatomic,strong) Function1 newCellBlock;

/**
 * If this is <nil> then this cell is readonly
 * if this is non-nil the renderer returned will be used for editing
 */
@property (nonatomic,strong) OTMEditDetailCellRenderer *editCellRenderer;

// Table View Delegate methods
@property (nonatomic,strong) Function2v clickCallback;
@property (nonatomic,assign) CGFloat cellHeight;

@property (nonatomic, strong) UIViewController *originatingDelegate;

/**
 * The original string value of the cell when it was built
 */
@property (nonatomic,strong) NSString *initialCellDisplayValue;

/**
 * Set to YES whenever the value of the cell is cleared by the user.
 */
@property (nonatomic,assign) BOOL wasCleared;

- (id)initWithDataKey:(NSString *)dkey;
- (id)initWithDataKey:(NSString *)dkey editRenderer:(OTMEditDetailCellRenderer *)edit;

/**
 * Given a tableView create a new cell (or reuse an old one), prepare
 * it with the given data and this cells rending info and return it
 */
ABSTRACT_METHOD
- (UITableViewCell *)prepareCell:(NSDictionary *)data inTable:(UITableView *)tableView;

/**
 * Return all cells of a given type for a particular table. In most cases this
 * will return an array with one cell. Some fields have multiple cells
 * (stewardship and alerts).
 */
- (NSArray *)prepareAllCells:(NSDictionary *)data inTable:(UITableView *)tableView withOriginatingDelegate:(UINavigationController *)delegate;

/**
 * Given a specific peice of data, return a cell. Needed so that a cell can be
 * created from fields with multiple cells.
 */
ABSTRACT_METHOD
- (UITableViewCell *)prepareCellSorterWithData:(NSDictionary *)data
                                       inTable:(UITableView *)tableView;

@end


@interface OTMBenefitsDetailCellRenderer : OTMDetailCellRenderer

@property (nonatomic,strong) OTMBenefitsTableViewCell *cell;
@property (nonatomic,strong) NSString *model;
@property (nonatomic,strong) NSString *key;

- (id)initWithModel:(NSString *)model key:(NSString *)key;

@end


/**
 * Render cells for editing
 */
@interface OTMEditDetailCellRenderer : OTMDetailCellRenderer

@property (nonatomic,assign) BOOL inited;

ABSTRACT_METHOD
- (NSDictionary *)updateDictWithValueFromCell:(NSDictionary *)dict;

@end


/**
 * Render a simple label
 */
@interface OTMLabelDetailCellRenderer : OTMDetailCellRenderer

@property (nonatomic,strong) NSString *label;
@property (nonatomic,strong) OTMFormatter *formatter;
@property BOOL isDateField;


- (id)initWithDataKey:(NSString *)dkey
         editRenderer:(OTMEditDetailCellRenderer *)edit
                label:(NSString *)labeltxt
            formatter:(OTMFormatter *)fmt
               isDate:(BOOL)dType;

@end


@interface OTMLabelEditDetailCellRenderer : OTMEditDetailCellRenderer<OTMDetailTableViewCellDelegate>

@property (nonatomic,assign) UIKeyboardType keyboard;
@property (nonatomic,strong) NSString *label;
@property (nonatomic,strong) NSString *updatedString;
@property (nonatomic,strong) OTMFormatter *formatter;
@property BOOL isDateField;

- (id)initWithDataKey:(NSString *)dkey
                label:(NSString *)label
             keyboard:(UIKeyboardType)keyboard
            formatter:(OTMFormatter *)formatter
               isDate:(BOOL)dType;

@end


@interface OTMDBHEditDetailCellRenderer : OTMEditDetailCellRenderer<OTMDetailTableViewCellDelegate>

@property (nonatomic,strong) OTMDBHTableViewCell *cell;
@property (nonatomic,strong) OTMFormatter *formatter;

-(id)initWithDataKey:(NSString *)dkey formatter:(OTMFormatter *)formatter;

@end


/**
 * Shows a static cell that allows a click event
 * (Such as for selecting species)
 *
 * When the user clicks on the cell "callback"
 * is invoked. When editing is finished the value
 * (if non-nil) from data is used as the edited value
 */
@interface OTMStaticClickCellRenderer : OTMEditDetailCellRenderer

- (id)initWithName:(NSString *)aName
               key:(NSString *)key
     clickCallback:(Function2v)aCallback;

- (id)initWithKey:(NSString *)key clickCallback:(Function2v)aCallback;

@property (nonatomic,strong) NSString *defaultName;
@property (nonatomic,strong) NSString *name;
@property (nonatomic,strong) id data;
@property (nonatomic,strong,readonly) UITableViewCell *detailcell;

@end


/**
 * A container to store rendered cells and to be able to sort them if need be.
 * Groups of these can be sorted based on the having the same sort key and can
 * be sorted by the sortdata contained in them. Additionally these retain
 * cellheight since that is requested of each cell placed in the tree detail
 * table.
 */
@interface OTMCellSorter : NSObject

@property (nonatomic, strong) NSString *sortKey;
@property (nonatomic, strong) NSString *sortData;
@property (nonatomic, strong) UITableViewCell *cell;
@property (nonatomic, strong) NSMutableDictionary *originalData;
@property (nonatomic, assign) CGFloat cellHeight;
@property (nonatomic,strong) Function2v clickCallback;

- (id)initWithCell:(UITableViewCell *)cell
           sortKey:(NSString *)key
          sortData:(NSString *)data
            height:(CGFloat)height
     clickCallback:(Function2v)callback;

- (id)initWithCell:(UITableViewCell *)cell
           sortKey:(NSString *)key
          sortData:(NSString *)data
      originalData:(NSMutableDictionary *)startData
            height:(CGFloat)height
     clickCallback:(Function2v)callback;

@end
