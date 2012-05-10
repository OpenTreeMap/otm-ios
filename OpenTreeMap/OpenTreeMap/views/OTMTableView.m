//
//  OTMTableView.m
//  OpenTreeMap
//
//  Created by Adam Hinz on 5/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OTMTableView.h"

@implementation OTMTableView

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
