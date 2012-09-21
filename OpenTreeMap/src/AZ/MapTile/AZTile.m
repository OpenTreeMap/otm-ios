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

#import "AZTile.h"

@implementation AZTile

@synthesize points, borderTiles, mapRect, zoomScale, cacheKey;

/**
 * Create a new AZTile
 */
-(id)initWithPoints:(AZPointerArrayWrapper *)p 
        borderTiles:(NSDictionary *)b
            mapRect:(MKMapRect)m 
          zoomScale:(MKZoomScale)z {
    self = [super init];
    if (self) {
        points = p;
        borderTiles = b;
        mapRect = m;
        zoomScale = z;
        cacheKey = [AZTile tileKeyWithMapRect:mapRect zoomScale:zoomScale];
    }
    return self;
}

-(BOOL)fullyLoaded {
    return [borderTiles count] == 8;
}

-(AZTile *)createTileWithNeighborTile:(AZTile *)tile
                          atDirection:(AZDirection)d {
    NSMutableDictionary *newborder = [NSMutableDictionary dictionaryWithDictionary:borderTiles];
    [newborder setObject:[tile points] forKey:d];

    return [[AZTile alloc] initWithPoints:points
                              borderTiles:newborder
                                  mapRect:mapRect
                                zoomScale:zoomScale];
}

-(AZTile *)createTileWithoutNeighborTileAtDirection:(AZDirection)d {
    NSMutableDictionary *newborder = [NSMutableDictionary dictionaryWithDictionary:borderTiles];
    [newborder removeObjectForKey:d];

    return [[AZTile alloc] initWithPoints:points
                              borderTiles:newborder
                                  mapRect:mapRect
                                zoomScale:zoomScale];
}

-(NSString *)description {
    return [NSString stringWithFormat:@"AZTile(npoints=%d,borderTiles=%@,mapRect=%@)",
                     points.length,
                     [borderTiles allKeys],
                     MKStringFromMapRect(mapRect)];
}

+(NSString *)tileKeyWithMapRect:(MKMapRect)m zoomScale:(MKZoomScale)zs {
    return [NSString stringWithFormat:@"tile:%@:zoom=%f",MKStringFromMapRect(m),zs];
}

+(NSString *)tileKey:(AZTile *)t {
    return t.cacheKey;
}

@end
