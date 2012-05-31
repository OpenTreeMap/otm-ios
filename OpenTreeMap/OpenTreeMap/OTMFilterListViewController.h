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

@end 

@interface OTMFilterListViewController : UIViewController

@property (nonatomic,strong) Function1v callback;

@property (nonatomic,strong) IBOutlet UISwitch *missingTree;
@property (nonatomic,strong) IBOutlet UISwitch *missingDBH;
@property (nonatomic,strong) IBOutlet UISwitch *missingSpecies;

- (void)setFilters:(OTMFilters *)f;

@end
