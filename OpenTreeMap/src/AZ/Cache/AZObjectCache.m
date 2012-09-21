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

#import "AZObjectCache.h"

@implementation AZObjectCache

- (void)cacheObject:(id)object forKey:(NSObject<NSCopying> *)key
{
    ABSTRACT_METHOD_BODY
}

- (id)objectForKey:(NSObject<NSCopying> *)key
{
    ABSTRACT_METHOD_BODY
}

- (void)removeObjectWithKey:(NSObject<NSCopying> *)key
{
    ABSTRACT_METHOD_BODY
}

- (void)purgeCache
{
    ABSTRACT_METHOD_BODY
}

@end
