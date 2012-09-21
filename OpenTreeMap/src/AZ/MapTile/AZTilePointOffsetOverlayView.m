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

#import "AZTilePointOffsetOverlayView.h"
#import "AZPointOffsetOverlay.h"
#import "AZTileCacheKey.h"

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
