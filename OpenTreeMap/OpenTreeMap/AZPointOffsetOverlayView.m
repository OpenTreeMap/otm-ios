/*

 AZPointOffsetOverlayView.m

 Created by Justin Walgran on 2/21/12.
 
 License
 =======
 Copyright (c) 2012 Azavea. All rights reserved.

 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
  
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
  
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*/

#import <math.h>
#import "AZPointOffsetOverlayView.h"
#import "AZPointOffsetOverlay.h"
#import "AZTileRenderer.h"
#import "AZTileCacheKey.h"
#import "AZTileQueue.h"

@implementation AZPointOffsetOverlayView

@synthesize tileAlpha, pointStamp, memoryTileCache, memoryPointCache, memoryFilterTileCache, filters, maximumStampSize;

- (id)initWithOverlay:(id<MKOverlay>)overlay {
    if (self = [super initWithOverlay:overlay]) {
        memoryTileCache = [[AZGeoCache alloc] init];
        memoryFilterTileCache = [[AZGeoCache alloc] init];
        memoryPointCache = [[AZGeoCache alloc] init];
        self.pointStamp = [UIImage imageNamed:@"tree_icon"];
        self.tileAlpha = 1.0f;
        self.clipsToBounds = NO;
        loading = [NSMutableSet set];
        loadingFilter = [NSMutableSet set];
        maximumStampSize = CGSizeMake(30,30);
    }
    
    return self;
}

- (void)sendFilterTileRequestWithMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale
{
    [self sendTileRequestWithMapRect:mapRect zoomScale:zoomScale tileCache:memoryFilterTileCache pointCache:nil filters:filters mask:loadingFilter];
}

/**
 Send an asynchronous request to a server that returns a point offset 'tile' then render those point offsets to an image and then notify MapKit that the region is ready to be redrawn.
 @param url The url to be opened
 @param mapRect The extent of the map tile being requested
 @param zoomScale The ratio of pixels to map units for the reqested map tile
 */
- (void)sendTileRequestWithMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale {
    [self sendTileRequestWithMapRect:mapRect zoomScale:zoomScale tileCache:memoryTileCache pointCache:memoryPointCache filters:nil mask:loading];
}

- (void)sendTileRequestWithMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale
                         tileCache:(AZGeoCache *)tileCache pointCache:(AZGeoCache *)pointCache
                           filters:(OTMFilters *)fs
                              mask:(NSMutableSet *)mask
{    
    //    __block AZPointOffsetOverlayView *blockSelf = self;
    OTMAPI *api = [[OTMEnvironment sharedEnvironment] api];
    [api getPointOffsetsInTile:MKCoordinateRegionForMapRect(mapRect) filters:fs mapRect:mapRect zoomScale:zoomScale callback:^(AZPointCollection *p, NSError *e) {
            [api.renders queueRequest:[[AZTileRequest alloc] initWithRegion:MKCoordinateRegionForMapRect(mapRect)
                                                                    mapRect:mapRect
                                                                  zoomScale:zoomScale
                                                                    filters:filters
                                                                   callback:nil
                                                                  operation:^(AZTileRequest *r) {
                        [AZTileRenderer createImageWithPoints:p
                                                        error:e
                                                      mapRect:mapRect
                                                    zoomScale:zoomScale
                                                    tileAlpha:tileAlpha
                                                      filters:fs
                                                    tileCache:tileCache
                                                   pointCache:pointCache
                                       displayRequestCallback:^(MKMapRect m, MKZoomScale z) 
                                        {
                                            dispatch_async(dispatch_get_main_queue(), 
                                                           ^{
                                                               [self setNeedsDisplayInMapRect:m zoomScale:z]; 
                                                           });
                                        }];
                        @synchronized(mask) {
                            [mask removeObject:[AZTileCacheKey keyWithMapRect:mapRect zoomScale:zoomScale]];
                }
                    }]];
        }];
}

#pragma mark MKOverlayView methods

/**
 Returns a Boolean value indicating whether the overlay view is ready to draw its content.
 */
- (BOOL)canDrawMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale 
{
    if ([filters customFiltersActive]) {
        if ([memoryFilterTileCache getObjectForMapRect:mapRect zoomScale:zoomScale] == nil) {
            @synchronized(loadingFilter) {
                if (![loadingFilter containsObject:[AZTileCacheKey keyWithMapRect:mapRect zoomScale:zoomScale]]) {
                    [loadingFilter addObject:[AZTileCacheKey keyWithMapRect:mapRect zoomScale:zoomScale]];
                    [self sendFilterTileRequestWithMapRect:mapRect zoomScale:zoomScale];
                }
            }
            return NO;
        }
    }
    if ([memoryTileCache getObjectForMapRect:mapRect zoomScale:zoomScale] == nil) {
        // If the cache does not have a tile for the requested URL, start a new request in the backround and
        // return NO to let the caller know that the tile is not yet loaded.
        @synchronized(loading) {
            if (![loading containsObject:[AZTileCacheKey keyWithMapRect:mapRect zoomScale:zoomScale]]) {
                [loading addObject:[AZTileCacheKey keyWithMapRect:mapRect zoomScale:zoomScale]];
                [self sendTileRequestWithMapRect:mapRect zoomScale:zoomScale];
            }
        }
        return NO;
    }

    return YES;
}


-(void)setFilters:(OTMFilters *)f {
  [memoryFilterTileCache purgeCache];
  filters = f;
  [self setNeedsDisplay];  
}

/**
 Draws the contents of the overlay view.
 */
- (void)drawMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale inContext:(CGContextRef)context 
{   
    UIGraphicsPushContext(context);
    
    [self renderTilesInMapRect:mapRect zoomScale:zoomScale alpha:1.0 inContext:context withCache:memoryTileCache];    
    
    if ([filters active]) {
      [self renderFilteredTilesInMapRect:mapRect zoomScale:zoomScale alpha:1.0 inContext:context filters:filters];
    }

    UIGraphicsPopContext();
    
}

-(void)renderFilteredTilesInMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale alpha:(CGFloat)alpha inContext:(CGContextRef)context filters:(OTMFilters *)f {
 
    // If we are using the standard filters we don't need to pull down more data
    // instead we will render it in place
    if ([filters standardFiltersActive]) {
        if (![self.memoryFilterTileCache getObjectForMapRect:mapRect
                                                   zoomScale:zoomScale]) {
            AZPointCollection *pcol = [self.memoryPointCache getObjectForMapRect:mapRect zoomScale:zoomScale];
            if (pcol) {
                int filter = 0;
                if (f.missingDBH) { filter |= AZTileHasDBH; }
                if (f.missingTree) { filter |= AZTileHasTree; }
                if (f.missingSpecies) { filter |= AZTileHasSpecies; }

                UIImage *image = [AZTileRenderer createImageWithOffsets:pcol.points
                                                              zoomScale:zoomScale
                                                                  alpha:1.0
                                                                 filter:filter
                                                                   mode:AZTileFilterModeAny];
            
                [self.memoryFilterTileCache cacheObject:image forMapRect:mapRect zoomScale:zoomScale];
            }
        }
    }

    [self renderTilesInMapRect:mapRect zoomScale:zoomScale alpha:alpha inContext:context withCache:memoryFilterTileCache];
}

-(void)renderTilesInMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale alpha:(CGFloat)alpha inContext:(CGContextRef)context withCache:(AZGeoCache *)cache {
    CGRect drawRect = [self rectForMapRect:mapRect];

    UIImage *stamp = [AZTileRenderer stampForZoom:zoomScale];
    CGRect centerRect = CGRectInset(drawRect, -(stamp.size.height)/zoomScale, -(stamp.size.height)/zoomScale);
    
    UIImage* imageData = [cache getObjectForMapRect:mapRect zoomScale:zoomScale];
    
    if (imageData == nil) { return; }
    
    [imageData drawInRect:centerRect blendMode:kCGBlendModeNormal alpha:alpha];
    
}

- (void)disruptCacheForCoordinate:(CLLocationCoordinate2D)coordinate
{
    [memoryTileCache disruptCacheForCoordinate:coordinate];
    [loading removeAllObjects];
}

@end
