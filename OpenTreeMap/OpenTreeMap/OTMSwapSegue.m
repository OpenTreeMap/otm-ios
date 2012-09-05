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
    
    UIView *dView = [[self destinationViewController] view];
    dView.frame = sFrame;
    [pView addSubview:dView];
}

@end
