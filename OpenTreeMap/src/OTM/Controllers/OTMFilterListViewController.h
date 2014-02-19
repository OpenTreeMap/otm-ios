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
#import "OTMButton.h"

typedef enum {
    kOTMFiltersShowAll = 0,
    kOTMFiltersShowRecent,
    kOTMFiltersShowPending
} OTMListFilterType;

@interface OTMFilters : NSObject

@property (nonatomic,strong) NSString *speciesName;
@property (nonatomic,strong) NSString *speciesId;

@property (nonatomic,assign) OTMListFilterType listFilterType;

@property (nonatomic,strong) NSArray *filters;

- (BOOL)active;
- (NSString *)filtersAsUrlParameter;
- (NSDictionary *)filtersDict;
- (BOOL)standardFiltersActive;
- (BOOL)customFiltersActive;

- (NSDictionary *)customFiltersDict;

- (NSString *)description;

@end

#define OTMFilterKeyType @"OTMFilterKeyType"
#define OTMFilterKeyName @"OTMFilterKeyName"
#define OTMFilterKeyKey  @"OTMFilterKeyKey"
#define OTMChoiceFilterChoiceKey @"OTMChoiceFilterChoice"

@interface OTMFilter : NSObject

/**
 * This is the view that the property will show
 */
@property (nonatomic,readonly) UIView *view;
@property (nonatomic,readonly) NSString *name;
@property (nonatomic,readonly) NSString *key;
@property (nonatomic,strong) id delegate;

- (NSDictionary *)queryParams;
- (BOOL)active;
- (void)clear;
- (void)resignFirstResponder;

@end

@interface OTMBoolFilter : OTMFilter

@property (nonatomic,readonly) UILabel *nameLbl;
@property (nonatomic,readonly) UISwitch *toggle;
@property (nonatomic,readonly) BOOL existanceFilter;

- (id)initWithName:(NSString *)nm key:(NSString *)k;
- (id)initWithName:(NSString *)nm key:(NSString *)k existanceFilter:(BOOL)existanceFilter;

@end

@interface OTMFilterSpacer : OTMFilter

@property (nonatomic,readonly) CGFloat space;

- (id)initWithSpace:(CGFloat)s;

@end


@interface OTMRangeFilter : OTMFilter

@property (nonatomic,readonly) UILabel *nameLbl;
@property (nonatomic,readonly) UITextField *minValue;
@property (nonatomic,readonly) UITextField *maxValue;

- (id)initWithName:(NSString *)nm key:(NSString *)k;

@end

@interface OTMChoiceFilter : OTMFilter

@property (nonatomic,readonly) OTMButton *button;
@property (nonatomic,readonly) UITableViewController *tvc;
@property (nonatomic,readonly) NSDictionary *selectedChoice;
@property (nonatomic,readonly) NSArray *allChoices;

- (id)initWithName:(NSString *)nm key:(NSString *)k choices:(NSArray *)choices;

@end



@interface OTMFilterListViewController : OTMScrollAwareViewController

@property (nonatomic,readonly) NSArray *filters;
@property (nonatomic,strong) Function1v callback;

@property (nonatomic,strong) IBOutlet UIScrollView *scrollView;
@property (nonatomic,strong) IBOutlet UIView *otherFiltersView;
@property (nonatomic,strong) IBOutlet UIButton *speciesButton;
@property (nonatomic,strong) NSString *speciesName;
@property (nonatomic,strong) NSString *speciesId;

- (IBAction)updateFilters:(id)sender;
- (IBAction)clearFilters:(id)sender;

- (void)setAllFilters:(OTMFilters *)f;

@end
