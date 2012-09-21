//
//  UIAlertView+Blocks.h
//  OpenTreeMap
//
//  Created by Adam Hinz on 3/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^UIAlertViewDelegateBlock)(UIAlertView *alertView, int btnIdx);

@interface UIAlertView (Blocks)

+(void)showAlertWithTitle:(NSString *)title 
                  message:(NSString *)message 
        cancelButtonTitle:(NSString *)cancelButtonTitle 
         otherButtonTitle:(NSString *)otherButtonTitle
                 callback:(UIAlertViewDelegateBlock) block;

@end
