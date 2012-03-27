//
//  OTMPasswordChangeViewController.h
//  OpenTreeMap
//
//  Created by Adam Hinz on 3/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OTMValidator.h"

@interface OTMPasswordChangeViewController : UIViewController

@property (nonatomic,strong) OTMValidator *validator;
@property (nonatomic,strong) IBOutlet UITextField *oldPassword;
@property (nonatomic,strong) IBOutlet UITextField *aNewPassword;
@property (nonatomic,strong) IBOutlet UITextField *aNewPasswordVerify;

@end
