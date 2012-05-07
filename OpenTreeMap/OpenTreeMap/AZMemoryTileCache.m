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
#import "AZTileCacheKey.h"

@implementation AZMemoryTileCache

- (void)cacheImage:(UIImage *)image forMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale
{
    [self cacheObject:image forKey:[AZTileCacheKey keyWithMapRect:mapRect zoomScale:zoomScale]];
}

- (UIImage *)getImageForMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale;
{
    return [self objectForKey:[AZTileCacheKey keyWithMapRect:mapRect zoomScale:zoomScale]];
}

- (void)disruptCacheForCoordinate:(CLLocationCoordinate2D)coordinate
{
    MKMapPoint point =  MKMapPointForCoordinate(coordinate);
    NSMutableArray *keysToBeDisrupted = [[NSMutableArray alloc] init];
    @synchronized (self) {
        for (AZTileCacheKey *key in keyQueue) {;
            if (MKMapRectContainsPoint(key.mapRect, point)) {
                [keysToBeDisrupted addObject:key];
            }
        }
        for (AZTileCacheKey *key in keysToBeDisrupted) {
            [self removeObjectWithKey:key];
        }
    }
}

#pragma mark AZMemoryObjectCache methods

- (NSUInteger)sizeInKBOf:(id)object {
    if ([object isKindOfClass:[UIImage class]]) {
        return [UIImagePNGRepresentation(object) length] / 1024;
    } else {
        return [super sizeInKBOf:object];
    }
}

@end
