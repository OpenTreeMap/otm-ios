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

#import "NSDictionary+MutableDeepCopy.h"

@implementation NSDictionary (MutableDeepCopy)

-(NSMutableDictionary *)mutableDeepCopy {
    NSMutableDictionary *mself = [NSMutableDictionary dictionary];
    
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        id mObj = nil;
        
        if ([obj respondsToSelector:@selector(mutableDeepCopy)]) {
            mObj = [obj mutableDeepCopy];
        } else if ([obj respondsToSelector:@selector(mutableCopyWithZone:)]) {
            mObj = [obj mutableCopy];
        } else {
            mObj = obj;
        }
        
        [mself setObject:mObj forKey:key];
    }];
    
    return mself;
}


@end
