//
//  AZTile.m
//  OpenTreeMap
//
//  Created by Adam Hinz on 8/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

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
