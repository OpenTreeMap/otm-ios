//
//  OTMLoginViewController.h
//  OpenTreeMap
//
//  Created by Adam Hinz on 3/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OTMUser.h"

@class OTMLoginViewController;
@class OTMLoginManager;

@protocol OTMLoginManagerDelegate <NSObject>

-(void)loginController:(OTMLoginViewController*)vc loggedInWithUser:(OTMUser*)user;
-(void)loginControllerCanceledLogin:(OTMLoginViewController*)vc;
-(void)loginController:(OTMLoginViewController*)vc registeredUser:(OTMUser*)user;

@end

@interface OTMLoginViewController : UIViewController

@property (nonatomic,weak) id<OTMLoginManagerDelegate> delegate;
@property (nonatomic,strong) IBOutlet UITextField *username;
@property (nonatomic,strong) IBOutlet UITextField *password;

@end
