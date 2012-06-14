//
//  OTMFilterListViewController.h
//  OpenTreeMap
//
//  Created by Adam Hinz on 5/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OTMScrollAwareViewController.h"

typedef enum {
    kOTMFiltersShowAll = 0,
    kOTMFiltersShowRecent,
    kOTMFiltersShowPending
} OTMListFilterType;

@interface OTMFilters : NSObject

@property (nonatomic,assign) BOOL missingTree;
@property (nonatomic,assign) BOOL missingDBH;
@property (nonatomic,assign) BOOL missingSpecies;
@property (nonatomic,strong) NSString *speciesName;
@property (nonatomic,strong) NSString *speciesId;

@property (nonatomic,assign) OTMListFilterType listFilterType;

@property (nonatomic,strong) NSArray *filters;

- (BOOL)active;
- (NSDictionary *)filtersDict;
- (BOOL)standardFiltersActive;
- (BOOL)customFiltersActive;

- (NSDictionary *)customFiltersDict;

@end 

#define OTMFilterKeyType @"OTMFilterKeyType"
#define OTMFilterKeyName @"OTMFilterKeyName"
#define OTMFilterKeyKey  @"OTMFilterKeyKey"

@interface OTMFilter : NSObject

+ (OTMFilter *)filterFromDictionary:(NSDictionary *)dict;

/**
 * This is the view that the property will show
 */
@property (nonatomic,readonly) UIView *view;
@property (nonatomic,readonly) NSString *name;
@property (nonatomic,readonly) NSString *key;
@property (nonatomic,strong) id delegate;

- (NSDictionary *)queryParams;
- (BOOL)active;

@end

@interface OTMBoolFilter : OTMFilter

@property (nonatomic,readonly) UILabel *nameLbl;
@property (nonatomic,readonly) UISwitch *toggle;

- (id)initWithName:(NSString *)nm key:(NSString *)k;

@end

@interface OTMRangeFilter : OTMFilter

@property (nonatomic,readonly) UILabel *nameLbl;
@property (nonatomic,readonly) UITextField *minValue;
@property (nonatomic,readonly) UITextField *maxValue;

- (id)initWithName:(NSString *)nm key:(NSString *)k;

@end


@interface OTMFilterListViewController : OTMScrollAwareViewController

@property (nonatomic,readonly) NSArray *filters;
@property (nonatomic,strong) Function1v callback;

@property (nonatomic,strong) IBOutlet UIScrollView *scrollView;
@property (nonatomic,strong) IBOutlet UIView *otherFiltersView;
@property (nonatomic,strong) IBOutlet UISwitch *missingTree;
@property (nonatomic,strong) IBOutlet UISwitch *missingDBH;
@property (nonatomic,strong) IBOutlet UISwitch *missingSpecies;
@property (nonatomic,strong) IBOutlet UIButton *speciesButton;
@property (nonatomic,strong) NSString *speciesName;
@property (nonatomic,strong) NSString *speciesId;

- (void)setAllFilters:(OTMFilters *)f;

@end
