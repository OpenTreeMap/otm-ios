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
    tileMapRectDict = [[NSMutableDictionary alloc] init];
    tileSizeDict = [[NSMutableDictionary alloc] init];
    tileKeyQueue = [[NSMutableArray alloc] init];
    cacheSizeInKB = 0;
}

- (void)disruptCacheForKey:(NSString *)key
{
    if ([tileImageDict objectForKey:key]) {
        [tileImageDict removeObjectForKey:key];
        [tileMapRectDict removeObjectForKey:key];
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
        [tileMapRectDict setObject:[self arrayFromMapRect:mapRect] forKey:key];
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

- (NSArray *)arrayFromMapRect:(MKMapRect)mapRect
{
   return [NSArray arrayWithObjects:
              [NSNumber numberWithFloat:mapRect.origin.x],
              [NSNumber numberWithFloat:mapRect.origin.y],
              [NSNumber numberWithFloat:mapRect.size.width],
              [NSNumber numberWithFloat:mapRect.size.height],
               nil];
}

- (MKMapRect)mapRectFromArray:(NSArray *)array
{
    return MKMapRectMake(
        [[array objectAtIndex:0] floatValue],
        [[array objectAtIndex:1] floatValue],
        [[array objectAtIndex:2] floatValue],
        [[array objectAtIndex:3] floatValue]);
}

- (UIImage *)getImageForMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale;
{
    @synchronized (tileImageDict) {
        NSString *key = [AZMemoryTileCache cacheKeyForMapRect:mapRect zoomScale:zoomScale];
        // When a cached tile is requested, move it to the end of the queue so that it is
        // least likely to get purged. 'Popular' tiles should be preserved.
        if ([tileImageDict objectForKey:key]) {
            [tileKeyQueue removeObject:key];
            [tileKeyQueue enqueue:key];
        }
        return [tileImageDict objectForKey:key];
    }
}

- (void)disruptCacheForCoordinate:(CLLocationCoordinate2D)coordinate
{
    MKMapPoint point =  MKMapPointForCoordinate(coordinate);
    NSMutableArray *keysToBeDisrupted = [[NSMutableArray alloc] init];
    @synchronized (self) {
        for (NSString *key in tileMapRectDict) {
            MKMapRect mapRect = [self mapRectFromArray:[tileMapRectDict objectForKey:key]];
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
