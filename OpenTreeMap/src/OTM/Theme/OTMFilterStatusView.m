//
//  OTMFilterStatusView.m
//  OpenTreeMap
//
//  Created by Justin Walgran on 7/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OTMFilterStatusView.h"
#import <QuartzCore/QuartzCore.h>

@implementation OTMFilterStatusView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self loadTheme];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    if (self) {
        [self loadTheme];
    }
    return self;
}

- (void)loadTheme
{
    self.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.layer.shadowOffset = CGSizeMake(0.0f, -1.0f);
    self.layer.shadowOpacity = 0.3;
    self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"filter_status_bg"]];
}

@end
