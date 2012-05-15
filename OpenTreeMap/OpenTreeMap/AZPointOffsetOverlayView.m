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

@synthesize tileAlpha, pointStamp, memoryTileCache;

- (id)initWithOverlay:(id<MKOverlay>)overlay {
    if (self = [super initWithOverlay:overlay]) {
        memoryTileCache = [[AZMemoryTileCache alloc] init];
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
    
    [[[OTMEnvironment sharedEnvironment] api] getPointOffsetsInTile:MKCoordinateRegionForMapRect(mapRect) callback:
     ^(CFArrayRef points, NSError* error) {
         if (error == nil) {
             UIImage* image = [AZPointOffsetOverlayView createImageWithOffsets:points stamp:[self stampForZoom:zoomScale] alpha:tileAlpha];
             
             [memoryTileCache cacheImage:image forMapRect:mapRect zoomScale:zoomScale];
             dispatch_async(dispatch_get_main_queue(), 
                            ^{
                                UIImage *stamp = [blockSelf stampForZoom:zoomScale];
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

-(UIImage *)stampForZoom:(MKZoomScale)zoom {
    int baseScale = 18 + log2f(zoom); // OSM 18 level scale
    
    NSString *imageName;
    switch(baseScale) {
    case 10:
    case 11:
        imageName = @"tree_zoom1";
        break;
    case 12:
    case 13:
        imageName = @"tree_zoom3";
        break;
    case 14:
    case 15:
        imageName = @"tree_zoom5";
        break;
    case 16:
        imageName = @"tree_zoom6";
        break;
    case 17:
        imageName = @"tree_zoom7";
        break;
    default:
        imageName = @"tree_zoom1";
        break;
    }
    
    
    return [UIImage imageNamed:imageName];
}

#pragma mark MKOverlayView methods

/**
 Returns a Boolean value indicating whether the overlay view is ready to draw its content.
 */
- (BOOL)canDrawMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale 
{
    if ([memoryTileCache getImageForMapRect:mapRect zoomScale:zoomScale]) {
        return YES;
    } else {
        // If the cache does not have a tile for the requested URL, start a new request in the backround and
        // return NO to let the caller know that the tile is not yet loaded.
        [self sendTileRequestWithMapRect:mapRect zoomScale:zoomScale];
        return NO;
    }
}

+(UIImage*)createImageWithOffsets:(CFArrayRef)offsets stamp:(UIImage*)stamp alpha:(CGFloat)alpha {
    CGSize imageSize = [stamp size];
    CGSize frameSize = CGSizeMake(256 + imageSize.width * 2, 256 + imageSize.height * 2);
    UIGraphicsBeginImageContext(frameSize);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(context);

//    Uncomment to debug issues with tile boundaries
//    CGContextSetStrokeColorWithColor(context, [[UIColor blackColor] CGColor]);
//    CGContextStrokeRect(context, CGRectMake(imageSize.height, imageSize.width, 256, 256));
//    
//    CGContextSetStrokeColorWithColor(context, [[UIColor redColor] CGColor]);
//    CGContextStrokeRect(context, CGRectMake(0, 0, frameSize.width, frameSize.height));
    
    CGRect baseRect = CGRectMake(-imageSize.width / 2.0f + imageSize.width, 
                                 -imageSize.height / 2.0f + imageSize.height, 
                                 imageSize.width, imageSize.height);
    
    for(int i=0;i<CFArrayGetCount(offsets);i++) {
        const OTMPoint* p = CFArrayGetValueAtIndex(offsets, i);
        CGRect rect = CGRectOffset(baseRect, p->xoffset, 255 - p->yoffset);
        
        [stamp drawInRect:rect blendMode:kCGBlendModeNormal alpha:alpha];
    }
    
    UIGraphicsPopContext();
    
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
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

/**
 Draws the contents of the overlay view.
 */
- (void)drawMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale inContext:(CGContextRef)context 
{   
    CGRect drawRect = [self rectForMapRect:mapRect];
    
    UIGraphicsPushContext(context);
    
    UIImage *stamp = [self stampForZoom:zoomScale];
    // Example draw rect by image size
    CGRect centerRect = CGRectInset(drawRect, -(stamp.size.height)/zoomScale, -(stamp.size.height)/zoomScale);
//    centerRect = CGRectOffset(centerRect, -stamp.size.width/zoomScale, -stamp.size.height/zoomScale);
    
    UIImage* imageData = [memoryTileCache getImageForMapRect:mapRect zoomScale:zoomScale];
    [imageData drawInRect:centerRect blendMode:kCGBlendModeNormal alpha:1];
    
    for(OTMDirection dir=North;dir<=NorthWest;dir++) {
        [self drawNeighbor:dir mapRect:mapRect zoomScale:zoomScale centerRect:centerRect stampSize:stamp.size];
    }
    
    UIGraphicsPopContext();
}

-(void)drawNeighbor:(OTMDirection)dir mapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale centerRect:(CGRect)centerRect stampSize:(CGSize)stampSize {

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
    
    UIImage *neigh = [memoryTileCache getImageForMapRect:neighMapRect zoomScale:zoomScale];
    
    // North
    if (neigh) {
        CGRect newRect = CGRectOffset(centerRect, offsetX, offsetY);
        [neigh drawInRect:newRect blendMode:kCGBlendModeNormal alpha:1];   
//        [self setNeedsDisplayInMapRect:MKMapRectIntersection(neighMapRect, mapRect) zoomScale:zoomScale];
    }        
}

- (void)disruptCacheForCoordinate:(CLLocationCoordinate2D)coordinate
{
    [memoryTileCache disruptCacheForCoordinate:coordinate];
}

@end
