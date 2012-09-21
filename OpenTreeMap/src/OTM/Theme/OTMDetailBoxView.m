//
//  OTMDetailBoxView.m
//  OpenTreeMap
//
//  Created by Adam Hinz on 5/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OTMDetailBoxView.h"
#import <QuartzCore/QuartzCore.h>

@implementation OTMDetailBoxView

-(void)loadTheme {
    fadeAtBottom = YES;
    self.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.layer.shadowOffset = CGSizeMake(0.0f, 1.0f);
    self.layer.shadowOpacity = 0.3;
}

@end
