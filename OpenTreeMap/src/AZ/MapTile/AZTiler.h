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

#import <Foundation/Foundation.h>
#import "AZPointParser.h"
#import "AZTile.h"
#import "OTMFilterListViewController.h"

typedef void (^AZTilerTileLoadedCallback)(CGImageRef image, BOOL done, MKMapRect rect, MKZoomScale zs);
typedef void (^AZTileImageCallback)(CGImageRef image);

@interface AZRenderedTile : NSObject

@property (nonatomic,assign) CGImageRef image;
@property (nonatomic,strong) NSMutableSet *pendingEdges;

-(id)init;

@end

/**
 * The tiler manages all aspects of tiling for a given tile layer
 *
 * In general, the tiler handles fetching, building, and storing
 * the tiles in a completely async way. 
 *
 * The delegate receives callbacks for the following events:
 * - point data loaded
 * - tile rendered (and if the rendering process is complete)
 * - sorting and prioritizing
 */
@interface AZTiler : NSObject {
    /**
     * NSDict<str(MKMapRect, MKZoomLevel),AZTile>
     */
    NSMutableDictionary *tiles;

    /**
     * The keyset for items in tiles, in the order
     * they were inserted into the array
     */
    NSMutableOrderedSet *keyList;

    /**
     * Current size of the cache in number of points
     */
    NSUInteger cacheSizeInPoints;

    /**
     * NSDict<str(MKMapRect, MKZoomLevel),AZRenderedTile>
     */
    NSMutableDictionary *renderedTiles;

    /**
     * NSOperationQueue<BlockCallback>
     * These are tiles that are waiting to be rendered. Whenever an operation
     * is executed it dequeues the first item in waitingForRender queue and
     * performs the render
     */
    NSOperationQueue *waitingForRenderOpQueue;

    /**
     * Set<AZTile>
     *
     * These are tiles that are waiting to be rendered
     */
    NSMutableOrderedSet *waitingForRenderQueue;

    /**
     * NSOperationQueue<BlockCallback>
     * These are tiles that are waiting to be rendered. Whenever an operation
     * is executed it dequeues the first item in waitingForRender queue and
     * performs the api to finish loading
     */
    NSOperationQueue *waitingForDownloadOpQueue;

    /**
     * Set<AZTileDownloadRequest>
     *
     * MKMapRects that are pending download
     */
    NSMutableOrderedSet *waitingForDownloadQueue;
}

/**
 * Called when a tile has finished rendering. Note that this may be called
 * before a tile has all edges loaded (so some edge effects may result)
 */
@property (nonatomic, copy) AZTilerTileLoadedCallback renderCallback;
@property (nonatomic, strong) OTMFilters *filters;

/**
 * Cache control properties
 */
@property (nonatomic, assign) NSUInteger maxNumberOfPoints;
@property (nonatomic, assign) NSUInteger maxNumberOfTiles;

/**
 * If a cache assertion is violated (max # of points/tiles)
 * clear enough cached data such that:
 * # of tiles < (max # of tiles)*cacheClearPercent
 * # of point < (max # of points)*cacheClearPercent
 *
 * @default 1.0
 */
@property (nonatomic, assign) float cacheClearPercent;

-(id)init;

/**
 * Request that the tiler send a tile request
 */
-(void)sendTileRequestWithMapRect:(MKMapRect)mapRect
                        zoomScale:(MKZoomScale)zs
                           region:(MKCoordinateRegion)region;

/**
 * Get the image for the given maprect and zoom scale. If the image has not
 * been loaded, the callback will be called with NULL
 */
-(void)withImageForMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale callback:(AZTileImageCallback)cb;

/**
 * Sort the current queues by distance from the current visible map rect with
 * the given zoom scale
 */
-(void)sortWithMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale;

/**
 * Clear all tiles with the specified zoom scale
 *
 * If andPoints is YES also clear out the backing points
 */
-(void)clearTilesWithZoomScale:(MKZoomScale)zoomScale andPoints:(BOOL)points;

/**
 * Clear all tiles that are not at the specified zoom scale
 *
 * If andPoints is YES also clear out the backing points
 */
-(void)clearTilesNotAtZoomScale:(MKZoomScale)zoomScale andPoints:(BOOL)points;

/**
 * Clear all tiles that contain the given point
 *
 * If andPoints is YES also clear out the backing points
 */
-(void)clearTilesContainingPoint:(MKMapPoint)mapPoint andPoints:(BOOL)points;


@end
