//
//  OTMPasswordResetViewController.h
//  OpenTreeMap
//
//  Created by Adam Hinz on 3/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OTMPasswordResetViewController : UIViewController

-(IBAction)resetPassword:(id)sender;

@property (nonatomic,strong) IBOutlet UITextField *email;

@end
