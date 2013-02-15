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
#import <QuartzCore/QuartzCore.h>

@implementation OTMDistanceTableViewCell

@synthesize thisLoc, distLabel, curLoc;

-(id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle
                reuseIdentifier:reuseIdentifier];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(distanceUpdated:)
                                                 name:kOTMDistaneTableViewCellRedrawDistance
                                                   object:nil];

        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(232,7,75,30)];
        label.backgroundColor = [UIColor colorWithRed:226/255.0 green:226/255.0 blue:226/255.0 alpha:1.0];
        label.textAlignment = UITextAlignmentCenter;
        label.textColor = [UIColor colorWithRed:46/255.0 green:136/255.0 blue:103/255.0 alpha:1.0];
        label.font = [UIFont systemFontOfSize:18];
        label.layer.cornerRadius = 15;
        label.layer.borderColor = [[UIColor colorWithRed:155/255.0 green:155/255.0 blue:155/255.0 alpha:1.0] CGColor];
        label.layer.borderWidth = 1;

        self.distLabel = label;

        [self addSubview:label];

        formatter = [[NSNumberFormatter alloc] init];
        [formatter setMaximumFractionDigits:0];
        [formatter setUsesGroupingSeparator:YES];
        [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
        [formatter setGroupingSeparator:
        [[NSLocale currentLocale] objectForKey:NSLocaleGroupingSeparator]];
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
        double dist = [curLoc distanceFromLocation:thisLoc];
        dist *= [[OTMEnvironment sharedEnvironment] distanceFromMetersFactor];

        NSString *unit = [[OTMEnvironment sharedEnvironment] dbhUnit];
        NSString *bunit = [[OTMEnvironment sharedEnvironment] distanceBiggerUnit];
        double unitF = [[OTMEnvironment sharedEnvironment] distanceBiggerUnitFactor];

        if (bunit && unitF > 0 && (dist/unitF) > 1.0) {
            dist = dist / unitF;
            unit = bunit;
        }

        [formatter setMaximumFractionDigits:dist < 10 ? 1 : 0];

        NSString *text = [formatter stringFromNumber:[NSNumber numberWithDouble:dist]];

        self.distLabel.text = [NSString stringWithFormat:@"%@%@",text,unit];
    }
}

-(void)distanceUpdated:(NSNotification *)note {
    [self setCurLoc:note.object];
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
