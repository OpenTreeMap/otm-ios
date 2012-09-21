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

#import "NSArray+MutableDeepCopy.h"

@implementation NSArray (MutableDeepCopy)

-(NSMutableArray *)mutableDeepCopy {
    NSMutableArray *marr = [NSMutableArray array];
    
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id mObj = nil;
        
        if ([obj respondsToSelector:@selector(mutableDeepCopy)]) {
            mObj = [obj mutableDeepCopy];
        } else if ([obj respondsToSelector:@selector(mutableCopy)]) {
            mObj = [obj mutableCopy];
        } else {
            mObj = obj;
        }
        
        [marr addObject:mObj];
    }];
    
    return marr;
}

@end
