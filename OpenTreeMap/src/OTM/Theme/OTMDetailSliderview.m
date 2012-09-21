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

#import "OTMDetailSliderview.h"
#import <QuartzCore/QuartzCore.h>

@implementation OTMDetailSliderview

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
    fadeAtBottom = NO;
    self.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.layer.shadowOffset = CGSizeMake(0.0f, -1.0f);
    self.layer.shadowOpacity = 0.3;
}

- (void)drawRect:(CGRect)rect
{    
    float pct = .90;   
    float height = self.frame.size.height;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    /// Main Gradient
    float color[] = { pct, pct, pct, 1.0 };
    CGColorRef startColor = [[UIColor whiteColor] CGColor];
    CGColorRef endColor = CGColorCreate(colorSpace, color);

    float locations[] = {0.0, 1.0};
    const void* colors[] = { startColor, endColor };
    CFArrayRef colorArray = CFArrayCreate(NULL, colors, 2, NULL);
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace,
                                                        colorArray, 
                                                        locations);
        
    CGFloat fadeOffset = fadeAtBottom ? 0 : 15;
    CGRect gframe = CGRectMake(0, fadeOffset, self.frame.size.width, height - 15);
    
    CGContextSetFillColorWithColor(context, [[self backgroundColor] CGColor]);
    CGContextFillRect(context, gframe);    
    
    CGContextSaveGState(context);
    CGContextAddRect(context,
                     gframe);
    CGContextClip(context);
    CGContextDrawLinearGradient(context, gradient, 
                                CGPointMake(CGRectGetMidX(gframe), fadeOffset),
                                CGPointMake(CGRectGetMidX(gframe), gframe.size.height + fadeOffset),
                                0);
    
    CGContextRestoreGState(context);

    CFRelease(colorArray);
    CGColorSpaceRelease(colorSpace);
}

@end
