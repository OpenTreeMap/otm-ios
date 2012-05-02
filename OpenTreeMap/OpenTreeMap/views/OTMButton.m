//
//  OTMButton.m
//  OpenTreeMap
//
//  Created by Adam Hinz on 5/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OTMButton.h"

@implementation OTMButton

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self loadTheme];
    }
    
    return self;
}

-(id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self loadTheme];
    }
    
    return self;
}

-(void)loadTheme {
    [self setBackgroundColor:[UIColor colorWithPatternImage:[[OTMEnvironment sharedEnvironment] buttonImage]]]; 

    self.titleLabel.textColor = [[OTMEnvironment sharedEnvironment] buttonTextColor];
}

@end
