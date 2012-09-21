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

#import "OTMSwapSegue.h"

@implementation OTMSwapSegue

-(void)perform {
    UIView *sView = [[self sourceViewController] view];
    CGRect sFrame = sView.frame;
    UIView *pView = [sView superview];
    [sView removeFromSuperview];    
    
    // Force a retain on the destinationViewController
    CFRetain((__bridge CFTypeRef)[self destinationViewController]);
    UIView *dView = [[self destinationViewController] view];
    dView.frame = sFrame;
    [pView addSubview:dView];
}

@end
