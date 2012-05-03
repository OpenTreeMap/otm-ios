/*
 
 AZMemoryTileCache.m
 
 Created by Justin Walgran on 5/2/12.
 
 License
 =======
 Copyright (c) 2012 Azavea. All rights reserved.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 */

#import "AZMemoryTileCache.h"
#import "NSMutableOrderedSet+Queue.h"

@implementation AZMemoryTileCache (Private)

- (void)initializeMembers 
{
    @synchronized (self) {
        tileImageDict = [[NSMutableDictionary alloc] init];
        tileMapRectDict = [[NSMutableDictionary alloc] init];
        tileSizeDict = [[NSMutableDictionary alloc] init];
        tileKeyQueue = [[NSMutableOrderedSet alloc] init];
        cacheSizeInKB = 0;
    }
}

- (void)disruptCacheForKey:(NSString *)key
{
    @synchronized (self) {
        if ([tileImageDict objectForKey:key]) {
            [tileImageDict removeObjectForKey:key];
            [tileMapRectDict removeObjectForKey:key];
            cacheSizeInKB -= [[tileSizeDict objectForKey:key] intValue];
            [tileSizeDict removeObjectForKey:key];
            [tileKeyQueue removeObject:key];
        }
    }
}

@end

@implementation AZMemoryTileCache

@synthesize maxCacheSizeInKB, cacheSizeInKB;

- (id)init
{
    self = [super init];
    if (self) {
        [self initializeMembers];
        maxCacheSizeInKB = 1024 * 8;
    }
    return self;
}

- (void)cacheImage:(UIImage *)image forMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale
{
    NSInteger imageSizeInKB = [UIImagePNGRepresentation(image) length] / 1024;
    if (imageSizeInKB > maxCacheSizeInKB) {
        [NSException raise:NSInvalidArgumentException format:@"The PNG representation of the image is larger than the max cache size of %dKB", maxCacheSizeInKB];
    }
    @synchronized (self) {
        NSString *key = [AZMemoryTileCache cacheKeyForMapRect:mapRect zoomScale:zoomScale];

        [self disruptCacheForKey:key];

        [tileImageDict setObject:image forKey:key];

        [tileMapRectDict setObject:[NSValue valueWithBytes:&mapRect objCType:@encode(MKMapRect)] forKey:key];

        [tileKeyQueue addObject:key];

        [tileSizeDict setObject:[NSNumber numberWithInt:imageSizeInKB] forKey:key];
        cacheSizeInKB += imageSizeInKB;
        
        while ([tileKeyQueue count] > 0 && cacheSizeInKB > maxCacheSizeInKB) {
            [self disruptCacheForKey:[tileKeyQueue firstObject]];
        }
    }
}

- (UIImage *)getImageForMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale;
{
    NSString *key = [AZMemoryTileCache cacheKeyForMapRect:mapRect zoomScale:zoomScale];
    // When a cached tile is requested, move it to the end of the queue so that it is
    // least likely to get purged. 'Popular' tiles should be preserved.
    if ([tileImageDict objectForKey:key]) {        
        [tileKeyQueue requeue:key];
    }
    return [tileImageDict objectForKey:key];
}

- (void)disruptCacheForCoordinate:(CLLocationCoordinate2D)coordinate
{
    MKMapPoint point =  MKMapPointForCoordinate(coordinate);
    NSMutableArray *keysToBeDisrupted = [[NSMutableArray alloc] init];
    @synchronized (self) {
        for (NSString *key in tileMapRectDict) {
            // The mapRect is boxed in an NSValue
            MKMapRect mapRect;
            [[tileMapRectDict objectForKey:key] getValue:&mapRect];
            if (MKMapRectContainsPoint(mapRect, point)) {
                [keysToBeDisrupted addObject:key];
            }
        }
        for (NSString *key in keysToBeDisrupted) {
            [self disruptCacheForKey:key];
        }
    }
}

- (void)purgeCache 
{
    @synchronized (self) {
        [self initializeMembers];
    }
}

@end
