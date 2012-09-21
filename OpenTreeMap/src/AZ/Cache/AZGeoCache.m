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

#import "AZGeoCache.h"
#import "AZTileCacheKey.h"

@implementation AZGeoCache

- (void)cacheObject:(id)image forMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale
{
    [self cacheObject:image forKey:[AZTileCacheKey keyWithMapRect:mapRect zoomScale:zoomScale]];
}

- (id)getObjectForMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale;
{
    return [self objectForKey:[AZTileCacheKey keyWithMapRect:mapRect zoomScale:zoomScale]];
}

- (UIImage *)removeFromCache:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale {
    AZTileCacheKey *key = [AZTileCacheKey keyWithMapRect:mapRect zoomScale:zoomScale];
    
    @synchronized (self) {
        UIImage *image = [self objectForKey:key];
        
        if (image) {
            [self removeObjectWithKey:key];
        }
        
        return image;
    }
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
