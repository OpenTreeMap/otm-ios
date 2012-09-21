//
//  OTMView.m
//  OpenTreeMap
//
//  Created by Adam Hinz on 5/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OTMView.h"

@implementation OTMView

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
    [self setBackgroundColor:[[OTMEnvironment sharedEnvironment] viewBackgroundColor]];
}

@end
