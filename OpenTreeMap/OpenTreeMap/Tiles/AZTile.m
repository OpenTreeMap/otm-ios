/*

 OTMMapDetailCellRenderer.h

 Created by Justin Walgran on 5/14/12.

 License
 =======
 Copyright (c) 2012 Azavea. All rights reserved.

 Permission is hereby granted, free of charge, to any person obtaining a copy 
 of this software and associated documentation files (the "Software"), to deal 
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
 copies of the Software, and to permit persons to whom the Software is furnished
 to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
*/

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
