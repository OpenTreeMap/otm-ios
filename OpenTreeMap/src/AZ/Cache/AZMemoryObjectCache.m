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

#import "AZMemoryObjectCache.h"
#import "AZCachedObject.h"

@implementation AZMemoryObjectCache

@synthesize cacheSizeInKB, maxCacheSizeInKB, secondsUntilObjectsExpire;

- (id)init
{
    return [self initWithMaxCacheSizeInKB:kAZMemoryObjectCacheDefaultMaxSizeInKB
                secondsUntilObjectsExpire:kAZMemoryObjectCacheDefaultSecondsUntilObjectsExpire];
}

- (id)initWithMaxCacheSizeInKB:(NSUInteger)maxSize secondsUntilObjectsExpire:(NSTimeInterval)seconds
{
    self = [super init];
    if (self) {
        maxCacheSizeInKB = maxSize;
        secondsUntilObjectsExpire = seconds;
        [self initializeMembers];
    }
    return self;
}

- (void)initializeMembers 
{
    @synchronized (self) {
        cache = [[NSMutableDictionary alloc] init];
        keyQueue = [[NSMutableOrderedSet alloc] init];
        cacheSizeInKB = 0;
    }
}

- (NSUInteger)sizeInKBOf:(id)object {
    return sizeof(object);
}

- (void)cacheObject:(id)object forKey:(NSObject<NSCopying> *)key
{
    NSUInteger size = [self sizeInKBOf:object];
    @synchronized (self) {
        if (size > self.maxCacheSizeInKB) {
            [NSException raise:NSInvalidArgumentException format:@"The object size of %zdKB is larger than the max cache size of %zdKB", size, maxCacheSizeInKB];
        }
        [self removeObjectWithKey:key];
        
        [cache setObject:[AZCachedObject createWithObject:object] forKey:key];
        [keyQueue addObject:key];
        cacheSizeInKB += size;
        
        while ([keyQueue count] > 0 && cacheSizeInKB > maxCacheSizeInKB) {
            [self removeObjectWithKey:[keyQueue firstObject]];
        }
    }
}

- (id)objectForKey:(NSObject<NSCopying> *)key
{
    // When a cached tile is requested, move it to the end of the queue so that it is
    // least likely to get purged. 'Popular' tiles should be preserved.
    @synchronized (self) {
        if ([cache objectForKey:key]) {        
            [keyQueue requeue:key];
        }
        AZCachedObject *cachedObject = [cache objectForKey:key];
        if (cachedObject) {
            if (secondsUntilObjectsExpire == kAZMemoryObjectCacheObjectsNeverExpire || [cachedObject ageInSeconds] <= secondsUntilObjectsExpire) {
                return [cachedObject object];
            } else {
                [self removeObjectWithKey:key];
                return nil;
            }
        } else {
            return nil;
        }
    }
}

- (void)removeObjectWithKey:(NSObject<NSCopying> *)key
{
    @synchronized (self) {
        if ([cache objectForKey:key]) {
            AZCachedObject *cachedObject = [cache objectForKey:key];
            NSUInteger size = [self sizeInKBOf:[cachedObject object]];
            [cache removeObjectForKey:key];
            [keyQueue removeObject:key];
            cacheSizeInKB -= size;
        }   
    }
}

- (void)purgeCache
{
    [self initializeMembers];
}

@end
