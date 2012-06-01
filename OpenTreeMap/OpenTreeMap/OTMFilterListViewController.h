//
//  OTMFilterListViewController.h
//  OpenTreeMap
//
//  Created by Adam Hinz on 5/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OTMFilters : NSObject

@property (nonatomic,assign) BOOL missingTree;
@property (nonatomic,assign) BOOL missingDBH;
@property (nonatomic,assign) BOOL missingSpecies;
@property (nonatomic,strong) NSArray *filters;

- (BOOL)active;
- (BOOL)standardFiltersActive;
- (BOOL)customFiltersActive;

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

ABSTRACT_METHOD
- (NSString *)queryString;

ABSTRACT_METHOD
- (BOOL)active;

@end

@interface OTMBoolFilter : OTMFilter

@property (nonatomic,readonly) UILabel *nameLbl;
@property (nonatomic,readonly) UISwitch *toggle;

- (id)initWithName:(NSString *)nm key:(NSString *)k;

@end

@interface OTMFilterListViewController : UIViewController

@property (nonatomic,readonly) OTMFilters *filters;
@property (nonatomic,strong) Function1v callback;

@property (nonatomic,strong) IBOutlet UIScrollView *scrollView;
@property (nonatomic,strong) IBOutlet UIView *otherFiltersView;
@property (nonatomic,strong) IBOutlet UISwitch *missingTree;
@property (nonatomic,strong) IBOutlet UISwitch *missingDBH;
@property (nonatomic,strong) IBOutlet UISwitch *missingSpecies;

- (void)setFilters:(OTMFilters *)f;

@end
