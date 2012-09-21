//
//  OTMScrollAwareViewController.h
//  OpenTreeMap
//
//  Created by Adam Hinz on 3/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OTMScrollAwareViewController : UIViewController

@property (nonatomic,weak) UITextField* activeField;
@property (nonatomic,strong) IBOutlet UIScrollView *scrollView;

/**
 * Override this method to handle the end of the form
 * being reached
 */
-(IBAction)completedForm:(id)sender;

@end
