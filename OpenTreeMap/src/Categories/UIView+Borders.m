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

#import "UIView+Borders.h"

@implementation UIView (Borders)

- (void)addHorizontalLineAtY:(CGFloat)y withColor:(UIColor*)color {
    CALayer *borderTop = [CALayer layer];
    borderTop.frame = CGRectMake(0.0f, y, self.frame.size.width, 0.5f);
    borderTop.backgroundColor = [color CGColor];
    [self.layer addSublayer:borderTop];
}

- (void)addBottomBorder {
    [self addBottomBorderWithColor:[UIColor lightGrayColor]];
}

- (void)addBottomBorderWithColor:(UIColor *)color {
    [self addHorizontalLineAtY:self.frame.size.height withColor:color];
}

- (void)addTopBorder {
    [self addTopBorderWithColor:[UIColor lightGrayColor]];
}

- (void)addTopBorderWithColor:(UIColor *)color {
    [self addHorizontalLineAtY:0.0 withColor:color];
}

@end
