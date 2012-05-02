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
#import "NSMutableArray+Queue.h"

@implementation AZMemoryTileCache (Private)

- (void)initializeMembers 
{
    tileImageDict = [[NSMutableDictionary alloc] init];
    tileMapRectAndScaleDict = [[NSMutableDictionary alloc] init];
    tileSizeDict = [[NSMutableDictionary alloc] init];
    tileKeyQueue = [[NSMutableArray alloc] init];
    cacheSizeInKB = 0;
}

- (void)disruptCacheForKey:(NSString *)key
{
    if ([tileImageDict objectForKey:key]) {
        [tileImageDict removeObjectForKey:key];
        [tileMapRectAndScaleDict removeObjectForKey:key];
        cacheSizeInKB -= [[tileSizeDict objectForKey:key] intValue];
//        NSLog(@"Cache size: %dKB", cacheSizeInKB);
        [tileSizeDict removeObjectForKey:key];
        [tileKeyQueue removeObject:key];
    }
}

@end

@implementation AZMemoryTileCache

@synthesize maxCacheSizeInKB;

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
    @synchronized (self) {
        NSString *key = [AZMemoryTileCache cacheKeyForMapRect:mapRect zoomScale:zoomScale];

        [self disruptCacheForKey:key];

        [tileImageDict setObject:image forKey:key];
        AZMapRectAndScale mapRectAndScale = { mapRect, zoomScale };
        [tileMapRectAndScaleDict setObject:[NSValue valueWithPointer:&mapRectAndScale] forKey:key];
        [tileKeyQueue enqueue:key];
        NSInteger imageSizeInKB = [UIImagePNGRepresentation(image) length] / 1024;
        [tileSizeDict setObject:[NSNumber numberWithInt:imageSizeInKB] forKey:key];
        cacheSizeInKB += imageSizeInKB;
//        NSLog(@"Cache size: %dKB", cacheSizeInKB);
        
        while ([tileKeyQueue count] > 0 && cacheSizeInKB > maxCacheSizeInKB) {
            NSString *key = [tileKeyQueue dequeue];
            [self disruptCacheForKey:key];
        }
    }
}

- (UIImage *)getImageForMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale;
{
    @synchronized (tileImageDict) {
        return [tileImageDict objectForKey:[AZMemoryTileCache cacheKeyForMapRect:mapRect zoomScale:zoomScale]];
    }
}

- (void)disruptCacheForCoordinate:(CLLocationCoordinate2D)coordinate
{
    @synchronized (self) {
        for (NSString *key in tileMapRectAndScaleDict) {
            NSValue *value = [tileMapRectAndScaleDict objectForKey:key];
            AZMapRectAndScale mapRectAndScale;
            [value getValue:&mapRectAndScale];
            if ([AZTileCache coordinate:coordinate isInMapRect:mapRectAndScale.mapRect]) {
                [self disruptCacheForKey:key];
            }
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
