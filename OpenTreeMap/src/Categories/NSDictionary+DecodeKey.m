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

#import "NSDictionary+DecodeKey.h"

@implementation NSDictionary (DecodeKey)

- (NSString*)decodeKey:(NSString *)keystr {
    NSArray* keylist = [keystr componentsSeparatedByString:@"."];
    
    id thing = self;
    for(NSString* key in keylist) {
        if ([thing respondsToSelector:@selector(objectForKey:)]) {
            thing = [thing objectForKey:key];
        } else {
            return nil;
        }
        
        if (thing == nil || thing == [NSNull null]) {
            return nil;
        }
    }
    
    return thing;
}

- (void)setObject:(id)obj forEncodedKey:(NSString *)keystr {
    NSArray* keylist = [keystr componentsSeparatedByString:@"."];
    
    id thing = self;
    for(int i=0;i<[keylist count] - 1;i++) {
        id key = [keylist objectAtIndex:i];
        if ([thing respondsToSelector:@selector(objectForKey:)]) {
            id aThing = [thing objectForKey:key];
            
            if (aThing == [NSNull null]) {
                aThing = [NSMutableDictionary dictionary];
                [thing setObject:aThing forKey:key];
            }
            
            thing = aThing;
        }
    }    
    
    [thing setObject:obj forKey:[keylist lastObject]];
}

@end
