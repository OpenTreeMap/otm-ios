// This file is part of the OpenTreeMap code.
//
// OpenTreeMap is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// OpenTreeMap is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with OpenTreeMap.  If not, see <http://www.gnu.org/licenses/>.

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
