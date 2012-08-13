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
#import "AZTilePointOffsetOverlayView.h"
#import "AZPointOffsetOverlay.h"
#import "AZTileRenderer.h"
#import "AZTileCacheKey.h"
#import "AZTileQueue.h"

@implementation AZTilePointOffsetOverlayView

@synthesize tiler, filterOnlyLayer;

- (id)initWithOverlay:(id<MKOverlay>)overlay {
    if (self = [super initWithOverlay:overlay]) {
        __block AZTilePointOffsetOverlayView *blockSelf = self;
        tiler = [[AZTiler alloc] init];
        tiler.renderCallback = ^(CGImageRef image, BOOL done, MKMapRect r, MKZoomScale z) {
            [blockSelf setNeedsDisplayInMapRect:r zoomScale:z];
        };

        // Don't keep chugging on cache clearing code
        tiler.cacheClearPercent = .80;        
        tiler.maxNumberOfTiles = 100;

        // Estimate around 7 bytes per point
        tiler.maxNumberOfPoints = 300000; // Should max out around 2 MB
    }
    
    return self;
}

- (void)setFilters:(OTMFilters *)f {
    [tiler setFilters:f];
}

- (OTMFilters *)filters {
    return [tiler filters];
}

#pragma mark MKOverlayView methods

/**
 Returns a Boolean value indicating whether the overlay view is ready to draw its content.
 */
- (BOOL)canDrawMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale 
{
    if (filterOnlyLayer && ([self filters] == nil || ![[self filters] active])) { 
        return YES; 
    }

    __block BOOL imageFound = YES;
    [tiler withImageForMapRect:mapRect zoomScale:zoomScale callback:^(CGImageRef image) {        
            if (image == NULL) {
                imageFound = NO;
                [tiler sendTileRequestWithMapRect:mapRect
                                        zoomScale:zoomScale
                                           region:MKCoordinateRegionForMapRect(mapRect)];
            }
        }];

    return imageFound;
}

/**
 Draws the contents of the overlay view.
 */
- (void)drawMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale inContext:(CGContextRef)context 
{   
    // Don't draw anything if we are a filter-only layer but no filters are set or active
    if (filterOnlyLayer && ([self filters] == nil || ![[self filters] active])) {
        return; 
    }

    [tiler withImageForMapRect:mapRect zoomScale:zoomScale callback:^(CGImageRef imageData) {
            if (imageData) {
                UIGraphicsPushContext(context); 

                CGRect drawRect = [self rectForMapRect:mapRect];
                CGContextDrawImage(context, drawRect, imageData);

                UIGraphicsPopContext();
            }
        }];
    
}

- (void)disruptCacheForCoordinate:(CLLocationCoordinate2D)coordinate {
    [self.tiler clearTilesContainingPoint:MKMapPointForCoordinate(coordinate) andPoints:YES];
}

@end
