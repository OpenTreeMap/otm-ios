//
//  AZTile.h
//  OpenTreeMap
//
//  Created by Adam Hinz on 8/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kAZNorth @"kNorth"
#define kAZNorthEast @"kNorthEast"
#define kAZEast @"kEast"
#define kAZSouthEast @"kSouthEast"
#define kAZSouth @"kSouth"
#define kAZSouthWest @"kSouthWest"
#define kAZWest @"kWest"
#define kAZNorthWest @"kNorthWest"

typedef NSString * AZDirection;

/**
 * AZTile represents data for a single tile on a map such as point data for the
 * tile and the tiles neighbors, as well as info about the tile extent
 *
 * This type must be treated as if it were immutable
 */
@interface AZTile : NSObject

/**
 * NSArray<*AZPoint>
 * List of all points in this tile. Do not modify this array or the points
 * within it.
 */
@property (nonatomic, strong, readonly) NSArray *points;

/**
 * NSDictionary<AZDirection,NSArray>
 * Contains bordering tile points indexed by kAZNorth, etc
 */
@property (nonatomic, strong, readonly) NSDictionary *borderTiles;

/**
 * Map rect for this tile
 */
@property (nonatomic, readonly) MKMapRect mapRect;

/**
 * Zoom scale
 */
@property (nonatomic, readonly) MKZoomScale zoomScale;

/**
 * A tile is 'fully loaded' if all of the edge tiles have been loaded as well
 */
@property (nonatomic, readonly) BOOL fullyLoaded;

/**
 * Create a new AZTile
 */
-(id)initWithPoints:(NSArray *)points 
        borderTiles:(NSDictionary *)borderTiles
            mapRect:(MKMapRect)mapRect
          zoomScale:(MKZoomScale)zoomScale;

-(NSString *)description;


/**
 * Create a new tile with a new neighbor tile in the given direction
 */               
-(AZTile *)createTileWithNeighborTile:(AZTile *)tile
                          atDirection:(AZDirection)d;


@end