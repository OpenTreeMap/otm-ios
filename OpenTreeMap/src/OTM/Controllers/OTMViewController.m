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

#import "OTMViewController.h"

@interface OTMViewController ()

@end

@implementation OTMViewController

- (NSString *)buildAddressStringFromPlotDictionary:(NSDictionary *)dict {
    NSMutableDictionary *plotDict = [dict objectForKey:@"plot"];
    NSArray *keys = @[@"address_street", @"address_city", @"address_zip"];

    NSMutableArray *addressComponents = [[NSMutableArray alloc] initWithCapacity:[keys count]];

    for (NSString *key in keys) {
        NSString *component = [plotDict objectForKey:key];
        if (component != nil && ![component isEqualToString: @""] && ![component  isEqualToString: @"<null>"]) {
            [addressComponents addObject:component];
        }
    }

    if ([addressComponents count] > 0) {
        return [addressComponents componentsJoinedByString:@" "];
    } else {
        return @"No Address";
    }
}

#pragma mark UISegmentedControl background drawing methods

// Adapted from http://stackoverflow.com/questions/19138252/uisegmentedcontrol-bounds

- (CGFloat)realWidthForSegmentedControl:(UISegmentedControl *)segmentedControl {
    CGFloat autosizedWidth = CGRectGetWidth(segmentedControl.bounds);
    autosizedWidth -= (segmentedControl.numberOfSegments - 1); // ignore the 1pt. borders between segments

    NSInteger numberOfAutosizedSegmentes = 0;
    NSMutableArray *segmentWidths = [NSMutableArray arrayWithCapacity:segmentedControl.numberOfSegments];
    for (NSInteger i = 0; i < segmentedControl.numberOfSegments; i++) {
        CGFloat width = [segmentedControl widthForSegmentAtIndex:i];
        if (width == 0.0f) {
            // auto sized
            numberOfAutosizedSegmentes++;
            [segmentWidths addObject:[NSNull null]];
        }
        else {
            // manually sized
            autosizedWidth -= width;
            [segmentWidths addObject:@(width)];
        }
    }

    CGFloat autoWidth = floorf(autosizedWidth/(float)numberOfAutosizedSegmentes);
    CGFloat realWidth = (segmentedControl.numberOfSegments-1);      // add all the 1pt. borders between the segments
    for (NSInteger i = 0; i < [segmentWidths count]; i++) {
        id width = segmentWidths[i];
        if (width == [NSNull null]) {
            realWidth += autoWidth;
        }
        else {
            realWidth += [width floatValue];
        }
    }
    return realWidth;
}

- (UIView *)addBackgroundViewBelowSegmentedControl:(UISegmentedControl *)segmentedControl {
    CGRect whiteViewFrame = segmentedControl.frame;
    whiteViewFrame.size.width = [self realWidthForSegmentedControl:segmentedControl];

    UIView *whiteView = [[UIView alloc] initWithFrame:whiteViewFrame];
    whiteView.backgroundColor = [UIColor whiteColor];
    whiteView.opaque = NO;
    whiteView.layer.opacity = 0.8;
    whiteView.layer.cornerRadius = 5.0f;
    [self.view insertSubview:whiteView belowSubview:segmentedControl];
    return whiteView;
}

- (void)updateBackgroundView:(UIView *)backgroundView forSegmentedControl:(UISegmentedControl *)segmentedControl {
    CGRect backgroundFrame = segmentedControl.frame;
    backgroundFrame.size.width = [self realWidthForSegmentedControl:segmentedControl];
    backgroundView.frame = backgroundFrame;
}

#pragma mark UIViewController methods

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
