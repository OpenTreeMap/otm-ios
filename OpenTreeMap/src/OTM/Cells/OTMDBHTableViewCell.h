//
//  OTMDBHTableViewCell.h
//  OpenTreeMap
//
//  Created by Adam Hinz on 4/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OTMDetailTableViewCell.h"

@interface OTMDBHTableViewCell : UITableViewCell

+(OTMDBHTableViewCell *)loadFromNib;

@property (nonatomic,strong) IBOutlet UITextField *circumferenceTextField;
@property (nonatomic,strong) IBOutlet UITextField *diameterTextField;

@property (nonatomic,weak) id<UITextFieldDelegate> tfDelegate;
@property (nonatomic,weak) id<OTMDetailTableViewCellDelegate> delegate;

@end
