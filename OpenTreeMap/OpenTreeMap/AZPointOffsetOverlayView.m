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

typedef enum {
    North = 1,
    NorthEast,
    East,
    SouthEast,
    South,
    SouthWest,
    West,
    NorthWest
} OTMDirection;

@implementation AZPointOffsetOverlayView

@synthesize tileAlpha, pointStamp, memoryTileCache, memoryPointCache, memoryFilterTileCache, filtered;

- (id)initWithOverlay:(id<MKOverlay>)overlay {
    if (self = [super initWithOverlay:overlay]) {
        memoryTileCache = [[AZGeoCache alloc] init];
        memoryFilterTileCache = [[AZGeoCache alloc] init];
        memoryPointCache = [[AZGeoCache alloc] init];
        self.pointStamp = [UIImage imageNamed:@"tree_icon"];
        self.tileAlpha = 1.0f;
        self.clipsToBounds = NO;
    }
    
    return self;
}

/**
 Send an asynchronous request to a server that returns a point offset 'tile' then render those point offsets to an image and then notify MapKit that the region is ready to be redrawn.
 @param url The url to be opened
 @param mapRect The extent of the map tile being requested
 @param zoomScale The ratio of pixels to map units for the reqested map tile
 */
- (void)sendTileRequestWithMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale 
{    
    __block AZPointOffsetOverlayView *blockSelf = self;
    
    [[[OTMEnvironment sharedEnvironment] api] getPointOffsetsInTile:MKCoordinateRegionForMapRect(mapRect) mapRect:mapRect zoomScale:zoomScale callback:
     ^(AZPointCollection *pcol, NSError* error) {
         if (error == nil) {
             CFArrayRef points = pcol.points;
             UIImage* image = [AZTileRenderer createImageWithOffsets:points zoomScale:zoomScale alpha:tileAlpha];
             
             [memoryPointCache cacheObject:pcol forMapRect:mapRect zoomScale:zoomScale];
             [memoryTileCache cacheObject:image forMapRect:mapRect zoomScale:zoomScale];
             dispatch_async(dispatch_get_main_queue(), 
                            ^{
                                UIImage *stamp = [AZTileRenderer stampForZoom:zoomScale];
                                MKMapRect adjustedRect = 
                                    MKMapRectInset(mapRect,
                                                   -(stamp.size.width*2.0)/zoomScale, 
                                                   -(stamp.size.height*2.0)/zoomScale);

                                [blockSelf setNeedsDisplayInMapRect:adjustedRect zoomScale:zoomScale];         
                            });
         } else {
             NSLog(@"Error loading tile images: %@", error);
         }
     }];     
}

#pragma mark MKOverlayView methods

/**
 Returns a Boolean value indicating whether the overlay view is ready to draw its content.
 */
- (BOOL)canDrawMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale 
{
    if ([memoryTileCache getObjectForMapRect:mapRect zoomScale:zoomScale]) {
        return YES;
    } else {
        // If the cache does not have a tile for the requested URL, start a new request in the backround and
        // return NO to let the caller know that the tile is not yet loaded.
        [self sendTileRequestWithMapRect:mapRect zoomScale:zoomScale];
        return NO;
    }
}

-(MKMapRect)mapRectForNeighbor:(MKMapRect)rect direction:(OTMDirection)dir {
    switch (dir) {
        case North:
            rect = MKMapRectOffset(rect, 0, -rect.size.height);
            break;
        case NorthEast:
            rect = MKMapRectOffset(rect, rect.size.width, -rect.size.height);
            break;
        case East:
            rect = MKMapRectOffset(rect, rect.size.width, 0);
            break;
        case SouthEast:
            rect = MKMapRectOffset(rect, rect.size.width, rect.size.height);
            break;
        case South:
            rect = MKMapRectOffset(rect, 0, rect.size.height);
            break;
        case SouthWest:
            rect = MKMapRectOffset(rect, -rect.size.width, rect.size.height);
            break;
        case West:
            rect = MKMapRectOffset(rect, -rect.size.width, 0);
            break;
        case NorthWest:
            rect = MKMapRectOffset(rect, -rect.size.width, -rect.size.height);
            break;
        default:
            break;
    }
    
    return rect;
}

-(void)setFiltered:(BOOL)filter {
    [memoryFilterTileCache purgeCache];
    [self setNeedsDisplay];
    filtered = filter;
}

/**
 Draws the contents of the overlay view.
 */
- (void)drawMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale inContext:(CGContextRef)context 
{   
    UIGraphicsPushContext(context);
    
    if (filtered) {
        [self renderTilesInMapRect:mapRect zoomScale:zoomScale alpha:1.0 inContext:context withCache:memoryTileCache];
        [self renderFilteredTilesInMapRect:mapRect zoomScale:zoomScale alpha:1.0 inContext:context];
    } else {
        [self renderTilesInMapRect:mapRect zoomScale:zoomScale alpha:1.0 inContext:context withCache:memoryTileCache];
    }
    
    UIGraphicsPopContext();
}

-(void)renderFilteredTilesInMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale alpha:(CGFloat)alpha inContext:(CGContextRef)context {
 
    // Stick the image into the filter tile cache and render
    if (![self.memoryFilterTileCache getObjectForMapRect:mapRect
                                               zoomScale:zoomScale]) {
        AZPointCollection *pcol = [self.memoryPointCache getObjectForMapRect:mapRect zoomScale:zoomScale];
        if (pcol) {
            UIImage *image = [AZTileRenderer createImageWithOffsets:pcol.points
                                                          zoomScale:zoomScale
                                                              alpha:1.0
                                                             filter:AZTileHasSpecies
                                                               mode:AZTileFilterModeAny];
            
            [self.memoryFilterTileCache cacheObject:image forMapRect:mapRect zoomScale:zoomScale];
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
    
    for(OTMDirection dir=North;dir<=NorthWest;dir++) {
        [self drawNeighbor:dir mapRect:mapRect zoomScale:zoomScale centerRect:centerRect stampSize:stamp.size alpha:alpha cache:cache];
    }
}

-(void)drawNeighbor:(OTMDirection)dir mapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale centerRect:(CGRect)centerRect stampSize:(CGSize)stampSize alpha:(CGFloat)alpha cache:(AZGeoCache *)cache {

    MKMapRect neighMapRect = [self mapRectForNeighbor:mapRect direction:dir];
    
    CGFloat offsetX = 0;
    CGFloat offsetY = 0;
    
    CGFloat stampHeightOffset = (stampSize.height*2.0)/zoomScale;
    CGFloat stampWidthOffset = (stampSize.width*2.0)/zoomScale;
    
    switch (dir) {
        case North:
            offsetX = 0;
            offsetY = -centerRect.size.height + stampHeightOffset;
            break;
        case NorthEast:
            offsetX = centerRect.size.width - stampWidthOffset;
            offsetY = -centerRect.size.height + stampHeightOffset;
            break;
        case East:
            offsetX = centerRect.size.width - stampWidthOffset;
            offsetY = 0;
            break;
        case SouthEast:   
            offsetX = centerRect.size.width - stampWidthOffset;
            offsetY = centerRect.size.height - stampHeightOffset;
            break;
        case South:   
            offsetX = 0;
            offsetY = centerRect.size.height - stampHeightOffset;
            break;
        case SouthWest:   
            offsetX = -centerRect.size.width + stampWidthOffset;
            offsetY = centerRect.size.height - stampHeightOffset;
            break;
        case West:
            offsetX = -centerRect.size.width + stampWidthOffset;
            offsetY = 0;
            break;      
        case NorthWest:
            offsetX = -centerRect.size.width + stampWidthOffset;
            offsetY = -centerRect.size.height + stampHeightOffset;
            break;            
            
        default:
            break;
    }
    
    UIImage *neigh = [cache getObjectForMapRect:neighMapRect zoomScale:zoomScale];
    
    if (neigh) {
        CGRect newRect = CGRectOffset(centerRect, offsetX, offsetY);
        [neigh drawInRect:newRect blendMode:kCGBlendModeNormal alpha:alpha];   
    }        
}

- (void)disruptCacheForCoordinate:(CLLocationCoordinate2D)coordinate
{
    [memoryTileCache disruptCacheForCoordinate:coordinate];
}

@end
