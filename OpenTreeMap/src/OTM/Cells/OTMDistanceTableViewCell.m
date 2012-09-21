//
//  OTMDistanceTableViewCell.m
//  OpenTreeMap
//
//  Created by Adam Hinz on 4/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OTMDistanceTableViewCell.h"

@implementation OTMDistanceTableViewCell

@synthesize thisLoc, distLabel, curLoc;

-(id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle
                reuseIdentifier:reuseIdentifier];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(distanceUpdated:) name:kOTMDistaneTableViewCellRedrawDistance
                                                   object:nil];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(230,0,65,44)];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = UITextAlignmentRight;
        label.textColor = [UIColor blueColor];
        label.font = [UIFont systemFontOfSize:18];
        
        self.distLabel = label;
        
        [self addSubview:label];
    }
    return self;
}

-(void)setThisLoc:(CLLocation *)aLoc {
    thisLoc = aLoc;
    
    [self updateDistance];
}

-(void)setCurLoc:(CLLocation *)aLoc {
    curLoc = aLoc;
    
    [self updateDistance];
}

-(void)updateDistance {
    if (curLoc && thisLoc) {
        self.distLabel.text = [NSString stringWithFormat:@"%0.0fm",[curLoc  distanceFromLocation:thisLoc]];
    }    
}

-(void)distanceUpdated:(NSNotification *)note {
    [self setCurLoc:note.object];
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
