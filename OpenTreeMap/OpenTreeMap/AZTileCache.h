/*
 
 AZTileCache.h
 
 Created by Justin Walgran on 5/2/12.
 
 License
 =======
 Copyright (c) 2012 Azavea. All rights reserved.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 */

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface AZTileCache : NSObject

typedef struct 
{
    MKMapRect mapRect;
    MKZoomScale zoomScale;
} AZMapRectAndScale;

/**
 Create a unique cache key for the specified mapRect and zoomScale.
 */
+ (NSString *)cacheKeyForMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale;

/**
 Save an image in the cache associated with the specified mapRect and zoomScale.
 */
ABSTRACT_METHOD
- (void)cacheImage:(UIImage *)image forMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale;

/**
 Save an image in the cache associated with the specified mapRect and zoomScale.
 */
ABSTRACT_METHOD
- (UIImage *)getImageForMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale;

/**
 Remove any images from the cache containing the specified coordinate.
 */
ABSTRACT_METHOD
- (void)disruptCacheForCoordinate:(CLLocationCoordinate2D)coordinate;

/**
 Remove all images from the cache.
 */
ABSTRACT_METHOD
- (void)purgeCache;

@end
