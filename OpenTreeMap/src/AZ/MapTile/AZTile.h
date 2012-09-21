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
#import <Foundation/Foundation.h>
#import "AZPointParser.h"

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
 * AZPointerArrayWrapper<**AZPoint>
 * List of all points in this tile. Do not modify this array or the points
 * within it.
 */
@property (nonatomic, strong, readonly) AZPointerArrayWrapper *points;

/**
 * NSDictionary<AZDirection,AZPointerArrayWrapper<**AZPoint>>
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
 * A key that can be used to cache this tile
 */
@property (nonatomic, readonly) NSString *cacheKey;

/**
 * Create a new AZTile
 */
-(id)initWithPoints:(AZPointerArrayWrapper *)points 
        borderTiles:(NSDictionary *)borderTiles
            mapRect:(MKMapRect)mapRect
          zoomScale:(MKZoomScale)zoomScale;

-(NSString *)description;


/**
 * Create a new tile with a new neighbor tile in the given direction
 */               
-(AZTile *)createTileWithNeighborTile:(AZTile *)tile
                          atDirection:(AZDirection)d;

-(AZTile *)createTileWithoutNeighborTileAtDirection:(AZDirection)d;

+(NSString *)tileKeyWithMapRect:(MKMapRect)m zoomScale:(MKZoomScale)zs;
+(NSString *)tileKey:(AZTile *)t;

@end
