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
        [self setBackgroundColor:[[OTMEnvironment sharedEnvironment] viewBackgroundColor]];
    }
    
    return self;
}

-(id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[[OTMEnvironment sharedEnvironment] viewBackgroundColor]];
    }
    
    return self;
}

@end
