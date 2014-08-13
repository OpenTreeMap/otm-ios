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

#import "OTMDetailCellRenderer.h"

@interface OTMUdfCollectionEditCellRenderer : OTMEditDetailCellRenderer

extern NSString * const UdfUpdateNotification;

@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *sortField;
@property (nonatomic, strong) NSString *selected;
@property (nonatomic, strong) NSString *typeKeyField;
@property (nonatomic, strong) NSString *editableKey;
@property (nonatomic, strong) NSString *editableDefaultValue;
@property (nonatomic, strong) NSDictionary *typeDict;
@property (nonatomic, strong) UITableViewController *controller;
@property (nonatomic, strong) NSMutableDictionary *startData;

- (id)initWithDataKey:(NSString *)dkey
             typeDict:(NSString *)dict
            sortField:(NSString *)sort
             keyField:(NSString *)keyField
             editable:(BOOL)canEdit
          editableKey:(NSString *)editKey
 editableDefaultValue:(NSString *)defaultValue;

@end


@interface OTMUdfAddMoreRenderer : OTMEditDetailCellRenderer

extern NSString * const UdfDataChangedForStepNotification;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIViewController *originalController;
@property (nonatomic, strong) UINavigationController *navController;
@property int step;
@property (nonatomic, strong) NSArray *steps;
@property (nonatomic, strong) NSArray *currentSteps;
@property (nonatomic, strong) NSString *field;
@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) NSString *displayName;
@property (nonatomic, strong) NSMutableDictionary *preparedNewUdf;


- (id)initWithDataStructure:(NSArray *)dataArray
                      field:(NSString *)field
                        key:(NSString *)key
                displayName:(NSString *)displayName;

- (id)initWithDataStructure:(NSArray *)dataArray;

@end


@interface OTMUdfChoiceTableViewController : UITableViewController

@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) NSString *choice;
@property (nonatomic, strong) NSArray *choices;
@property (nonatomic, strong) NSArray *choiceLabels;
- (id)initWithKey:(NSString *)key;
- (void)setChoices:(NSArray *)choicesArray;

@end


/**
 * Shows cells for UDF collections. These can in some cases create multiple
 * cells for a given field. These may need to be sorted together and ths we
 * store a sort field in addition to other information.
 */
@interface OTMCollectionUDFCellRenderer : OTMDetailCellRenderer

@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *sortField;
@property (nonatomic, strong) NSDictionary *typeDict;

- (id)initWithDataKey:(NSString *)dkey
             typeDict:(NSString *)dict
            sortField:(NSString *)sort
         editRenderer:(OTMEditDetailCellRenderer *)edit
      addMoreRenderer:(OTMUdfAddMoreRenderer *)more;

- (id)initWithEditRenderer:(OTMEditDetailCellRenderer *)edit;

@end


@interface OTMUdfCollectionHelper : NSObject

+ (NSDictionary *)generateDictFromString:(NSString *)dictString;
+ (NSString *)typeLabelFromType:(NSString *)type;
+ (NSString *)stringifyData:(id)data byType:(NSString *)type;
+ (NSString *)typeFromDataKey:(NSString *)dataKey;

@end
