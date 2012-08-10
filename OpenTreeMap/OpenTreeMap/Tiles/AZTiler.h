//
//  AZTiler.h
//  OpenTreeMap
//
//  Created by Adam Hinz on 8/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AZPointParser.h"
#import "AZTile.h"

typedef void (^AZTilerTileLoadedCallback)(UIImage *image, BOOL done, MKMapRect rect, MKZoomScale zs);

@interface AZRenderedTile : NSObject

@property (nonatomic,strong) UIImage *image;
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

-(id)init;

/**
 * Request that the tiler send a tile request
 */
-(void)sendTileRequestWithMapRect:(MKMapRect)mapRect
                        zoomScale:(MKZoomScale)zs
                           region:(MKCoordinateRegion)region;

/**
 * Get the image for the given maprect and zoom scale. If the image has not
 * been loaded, this method will return nil
 */
-(UIImage *)getImageForMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale;

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
