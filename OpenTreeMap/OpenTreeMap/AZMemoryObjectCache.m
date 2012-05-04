/*
 
 AZMemoryObjectCache.m
 
 Created by Justin Walgran on 5/3/12.
 
 License
 =======
 Copyright (c) 2012 Azavea. All rights reserved.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 */

#import "AZMemoryObjectCache.h"

@implementation AZMemoryObjectCache

@synthesize cacheSizeInKB, maxCacheSizeInKB;

- (id)init
{
    return [self initWithMaxCacheSizeInKB:kAZMemoryObjectCacheDefaultMaxSizeInKB];
}

- (id)initWithMaxCacheSizeInKB:(NSUInteger)maxSize
{
    self = [super init];
    if (self) {
        maxCacheSizeInKB = maxSize;
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
        
        [cache setObject:object forKey:key];
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
        return [cache objectForKey:key];
    }
}

- (void)removeObjectWithKey:(NSObject<NSCopying> *)key
{
    @synchronized (self) {
        if ([cache objectForKey:key]) {
            NSUInteger size = [self sizeInKBOf:[cache objectForKey:key]];
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
