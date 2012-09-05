//
//  OTMSwapSegue.m
//  OpenTreeMap
//
//  Created by Adam Hinz on 9/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OTMSwapSegue.h"

@implementation OTMSwapSegue

-(void)perform {
    UIView *sView = [[self sourceViewController] view];
    CGRect sFrame = sView.frame;
    UIView *pView = [sView superview];
    [sView removeFromSuperview];    
    
    // Force a retain on the destinationViewController
    CFRetain((__bridge CFTypeRef)[self destinationViewController]);
    UIView *dView = [[self destinationViewController] view];
    dView.frame = sFrame;
    [pView addSubview:dView];
}

@end
