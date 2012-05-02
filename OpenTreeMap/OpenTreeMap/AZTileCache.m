/*
 
 AZTileCache.m
 
 Created by Justin Walgran on 5/2/12.
 
 License
 =======
 Copyright (c) 2012 Azavea. All rights reserved.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 */

#import "AZTileCache.h"

@implementation AZTileCache

+ (NSString *)cacheKeyForMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale 
{
    return [NSString stringWithFormat:@"%f,%f,%f,%f,%f", mapRect.origin.x, mapRect.origin.y, mapRect.size.width, mapRect.size.width, zoomScale];
}

+ (BOOL)coordinate:(CLLocationCoordinate2D)coordinate isInMapRect:(MKMapRect)mapRect
{
    MKCoordinateRegion region = MKCoordinateRegionForMapRect(mapRect);
    float maxLat = region.center.latitude + region.span.latitudeDelta;
    float minLat = region.center.latitude - region.span.latitudeDelta;
    float maxLon = region.center.longitude + region.span.longitudeDelta;
    float minLon = region.center.longitude - region.span.longitudeDelta;
    return coordinate.latitude >= minLat 
        && coordinate.latitude <= maxLat 
        && coordinate.longitude >= minLon 
        && coordinate.longitude <= maxLon;
}

- (void)cacheImage:(UIImage *)image forMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale
{
    ABSTRACT_METHOD_BODY
}

- (UIImage *)getImageForMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale;
{
    ABSTRACT_METHOD_BODY
}

- (void)disruptCacheForCoordinate:(CLLocationCoordinate2D)coordinate
{
    ABSTRACT_METHOD_BODY
}

- (void)purgeCache 
{
    ABSTRACT_METHOD_BODY
}

@end
