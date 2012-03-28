//
//  OTMProfileViewController.h
//  OpenTreeMap
//
//  Created by Adam Hinz on 3/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OTMUser.h"
#import "OTMPictureTaker.h"

@interface OTMProfileViewController : UIViewController<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic,strong) OTMPictureTaker *pictureTaker;
@property (nonatomic,strong) OTMUser *user;
@property (nonatomic,strong) IBOutlet UITableView *tableView;

@end
