//
//  UIAlertView+Blocks.m
//  OpenTreeMap
//
//  Created by Adam Hinz on 3/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UIAlertView+Blocks.h"

@interface UIAlertViewBlockDelegate : NSObject<UIAlertViewDelegate>

@property (nonatomic,copy) UIAlertViewDelegateBlock callback;

@end
@implementation UIAlertViewBlockDelegate

@synthesize callback;

-(void)alertView:(UIAlertView *)aView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (callback != nil) {
        callback(aView, buttonIndex);
    }
    
    CFRelease((__bridge CFTypeRef)self);
}
@end

@implementation UIAlertView (Blocks)

+(void)showAlertWithTitle:(NSString *)title 
                message:(NSString *)message 
      cancelButtonTitle:(NSString *)cancelButtonTitle 
       otherButtonTitle:(NSString *)otherButtonTitle
            callback:(UIAlertViewDelegateBlock) block {
    
    UIAlertViewBlockDelegate *delegate = [[UIAlertViewBlockDelegate alloc] init];
    
    delegate.callback = block;
    
    CFRetain((__bridge CFTypeRef)delegate);
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:delegate cancelButtonTitle:cancelButtonTitle otherButtonTitles:otherButtonTitle,nil];
    alert.delegate = delegate;
    [alert show];
}

@end
