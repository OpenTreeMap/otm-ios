//
//  OTMRegistrationViewController.h
//  OpenTreeMap
//
//  Created by Adam Hinz on 3/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OTMScrollAwareViewController.h"
#import "OTMValidator.h"
#import "OTMPictureTaker.h"

@interface OTMRegistrationViewController : OTMScrollAwareViewController<UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic,readonly) OTMValidator *validator;
@property (nonatomic,readonly) OTMPictureTaker *pictureTaker;

@property (nonatomic,strong) IBOutlet UITextField *email; 
@property (nonatomic,strong) IBOutlet UITextField *password; 
@property (nonatomic,strong) IBOutlet UITextField *verifyPassword; 
@property (nonatomic,strong) IBOutlet UITextField *username; 
@property (nonatomic,strong) IBOutlet UITextField *firstName; 
@property (nonatomic,strong) IBOutlet UITextField *lastName; 
@property (nonatomic,strong) IBOutlet UITextField *zipCode;
@property (nonatomic,strong) IBOutlet UIImageView *profileImage; 
@property (nonatomic,strong) IBOutlet UIButton *changeProfilePic;

-(IBAction)getPicture:(id)sender;

@end
