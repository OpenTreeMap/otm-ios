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

@interface AZGeoCache : AZMemoryObjectCache

/**
 Save a tile image in the cache representing the specified mapRect and zoomScale.
 */
- (void)cacheObject:(id)image forMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale;

/**
 Retrieve a tile image from the cache for the specified mapRect and zoomScale.
 */
- (id)getObjectForMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale;

/**
 * Remove and return an image from the cache
 */
- (UIImage *)removeFromCache:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale;

/**
 Remove any tile image from the cache if the mapRect associated with the tile
 intersects the specified coordinate.
 */
- (void)disruptCacheForCoordinate:(CLLocationCoordinate2D)coordinate;

@end
