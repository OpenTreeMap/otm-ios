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

#import <Foundation/Foundation.h>
#import "AZObjectCache.h"
#import "NSMutableOrderedSet+Queue.h"

#define kAZMemoryObjectCacheDefaultMaxSizeInKB 8192
#define kAZMemoryObjectCacheDefaultSecondsUntilObjectsExpire 600.0
#define kAZMemoryObjectCacheObjectsNeverExpire 0

@interface AZMemoryObjectCache : AZObjectCache {
    NSUInteger cacheSizeInKB;
    NSMutableDictionary *cache;
    NSMutableOrderedSet *keyQueue;
}

@property (nonatomic) NSUInteger maxCacheSizeInKB;
@property (nonatomic, readonly) NSUInteger cacheSizeInKB;
@property (nonatomic) NSTimeInterval secondsUntilObjectsExpire;

/**
 Designated initializer
 */
- (id)initWithMaxCacheSizeInKB:(NSUInteger)maxSize secondsUntilObjectsExpire:(NSTimeInterval)seconds;

/**
 Return the size, in kilobytes of an object to be cached.
 */
- (NSUInteger)sizeInKBOf:(id)object;

@end
