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
    __block AZPointOffsetOverlayView *blockSelf = self;
    
    [[[OTMEnvironment sharedEnvironment] api] getPointOffsetsInTile:MKCoordinateRegionForMapRect(mapRect) filters:fs mapRect:mapRect zoomScale:zoomScale callback:
     ^(AZPointCollection *pcol, NSError* error) {
         if (error == nil && [tileCache getObjectForMapRect:mapRect zoomScale:zoomScale] == nil) {

             CFArrayRef points = pcol.points;

             UIImage *image;
             if (fs) {
                 image = [AZTileRenderer createFilterImageWithOffsets:points zoomScale:zoomScale alpha:tileAlpha];
             } else {
                 image = [AZTileRenderer createImageWithOffsets:points zoomScale:zoomScale alpha:tileAlpha];
             }

             @synchronized(self) {

                 image = [self fillInBorders:image mapRect:mapRect zoomScale:zoomScale tileCache:tileCache alpha:tileAlpha];
             
                 [pointCache cacheObject:pcol forMapRect:mapRect zoomScale:zoomScale];
                 [tileCache cacheObject:image forMapRect:mapRect zoomScale:zoomScale];

                 UIImage *stamp = [AZTileRenderer stampForZoom:zoomScale];

                 for(OTMDirection dir=North;dir<=NorthWest;dir++) {                    
                     MKMapRect neighMapRect = [self mapRectForNeighbor:mapRect direction:dir];
                     UIImage *neighborImage = [tileCache getObjectForMapRect:neighMapRect zoomScale:zoomScale];
                     if (neighborImage) {
                         neighborImage = [self fillInImage:neighborImage fromCenterImage:image directionFromCenter:dir stampSize:stamp.size];

                         [tileCache cacheObject:neighborImage forMapRect:neighMapRect zoomScale:zoomScale];
                         dispatch_async(dispatch_get_main_queue(), 
                                        ^{
                                            [blockSelf setNeedsDisplayInMapRect:neighMapRect zoomScale:zoomScale];         
                                        });
                     }
                 }

             }

             @synchronized(mask) {
                 [mask removeObject:[AZTileCacheKey keyWithMapRect:mapRect zoomScale:zoomScale]];
             }
             
             dispatch_async(dispatch_get_main_queue(), 
                            ^{
                                [blockSelf setNeedsDisplayInMapRect:mapRect];         
                            });
         } else {
             if (error != nil) {
                 NSLog(@"Error loading tile images: %@", error);
             } else {
                 NSLog(@"This tile is already cached.");
             }
         }
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

-(UIImage *)fillInBorders:(UIImage *)image mapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale tileCache:(AZGeoCache *)tiles alpha:(CGFloat)alpha  {

    UIGraphicsBeginImageContext([image size]);
    [image drawInRect:CGRectMake(0,0,image.size.width,image.size.height)];

    UIImage *stamp = [AZTileRenderer stampForZoom:zoomScale];

    for(OTMDirection dir=North;dir<=NorthWest;dir++) {
        [self drawNeighbor:dir mapRect:mapRect zoomScale:zoomScale stampSize:stamp.size alpha:alpha cache:tiles image:image];
    }

    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsPopContext();

    return newImage;
}

-(OTMDirection)oppositeDir:(OTMDirection)dir {
    switch (dir) {
        case North:
            return South;
        case NorthEast:
            return SouthWest;
        case East:
            return West;
        case SouthEast:   
            return NorthWest;
        case South:   
            return North;
        case SouthWest:   
            return NorthEast;
        case West:
            return East;
        case NorthWest:
            return SouthEast;
        default:
            return North;
    }
}

-(UIImage *)fillInImage:(UIImage *)image fromCenterImage:(UIImage *)cimage directionFromCenter:(OTMDirection)dirFrom stampSize:(CGSize)stampSize  {
    CGFloat offsetX = 0;
    CGFloat offsetY = 0;

    OTMDirection dir = [self oppositeDir:dirFrom];
    
    CGFloat stampHeightOffset = (stampSize.height*2.0);
    CGFloat stampWidthOffset = (stampSize.width*2.0);
    CGRect centerRect = CGRectMake(stampWidthOffset, stampHeightOffset, image.size.width, image.size.height);
    
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

    UIGraphicsBeginImageContext([image size]);

    [image drawInRect:CGRectMake(0,0,image.size.width,image.size.height)];

    CGRect newRect = CGRectMake(offsetX,offsetY,image.size.width,image.size.height); 
    [cimage drawInRect:newRect];

    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsPopContext();

    return newImage;
}

-(void)drawNeighbor:(OTMDirection)dir mapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale stampSize:(CGSize)stampSize alpha:(CGFloat)alpha cache:(AZGeoCache *)cache image:(UIImage*)image {
   
    CGFloat offsetX = 0;
    CGFloat offsetY = 0;
    
    CGFloat stampHeightOffset = (stampSize.height*2.0);
    CGFloat stampWidthOffset = (stampSize.width*2.0);
    CGRect centerRect = CGRectMake(stampWidthOffset, stampHeightOffset, image.size.width, image.size.height);
    
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

    MKMapRect neighMapRect = [self mapRectForNeighbor:mapRect direction:dir];    
    UIImage *neigh = [cache getObjectForMapRect:neighMapRect zoomScale:zoomScale];
    
    if (neigh) {
        CGRect newRect = CGRectMake(offsetX,offsetY,neigh.size.width,neigh.size.height); 
        [neigh drawInRect:newRect blendMode:kCGBlendModeNormal alpha:alpha];   
    }        
}

- (void)disruptCacheForCoordinate:(CLLocationCoordinate2D)coordinate
{
    [memoryTileCache disruptCacheForCoordinate:coordinate];
    [loading removeAllObjects];
}

@end
