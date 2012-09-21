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
