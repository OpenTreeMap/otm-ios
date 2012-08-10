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

@synthesize tiler;

- (id)initWithOverlay:(id<MKOverlay>)overlay {
    if (self = [super initWithOverlay:overlay]) {
        __block AZTilePointOffsetOverlayView *blockSelf = self;
        tiler = [[AZTiler alloc] init];
        tiler.renderCallback = ^(UIImage *image, BOOL done, MKMapRect r, MKZoomScale z) {
            [blockSelf setNeedsDisplayInMapRect:r zoomScale:z];
        };
    }
    
    return self;
}

#pragma mark MKOverlayView methods

/**
 Returns a Boolean value indicating whether the overlay view is ready to draw its content.
 */
- (BOOL)canDrawMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale 
{
    //    if (1.0/zoomScale > 10) return;
    //    if (!MKMapRectContainsPoint(mapRect, MKMapPointForCoordinate(CLLocationCoordinate2DMake(39.94809,-75.16366))) &&
    //     !MKMapRectContainsPoint(mapRect, MKMapPointForCoordinate(CLLocationCoordinate2DMake(39.95120,-75.16229))) &&
    //     !MKMapRectContainsPoint(mapRect, MKMapPointForCoordinate(CLLocationCoordinate2DMake(39.94932,-75.16101))) &&
    //     !MKMapRectContainsPoint(mapRect, MKMapPointForCoordinate(CLLocationCoordinate2DMake(39.95114,-75.16324))) &&
    //     !MKMapRectContainsPoint(mapRect, MKMapPointForCoordinate(CLLocationCoordinate2DMake(39.95038,-75.16339))) &&
    //     !MKMapRectContainsPoint(mapRect, MKMapPointForCoordinate(CLLocationCoordinate2DMake(39.94936,-75.16351))) &&
    //     !MKMapRectContainsPoint(mapRect, MKMapPointForCoordinate(CLLocationCoordinate2DMake(39.95100,-75.16090))) &&
    //     !MKMapRectContainsPoint(mapRect, MKMapPointForCoordinate(CLLocationCoordinate2DMake(39.94971,-75.16255))) &&
    //       !MKMapRectContainsPoint(mapRect, MKMapPointForCoordinate(CLLocationCoordinate2DMake(39.94904,-75.16368)))) return;

    UIImage *image = [tiler getImageForMapRect:mapRect zoomScale:zoomScale];
        
    if (!image) {
        [tiler sendTileRequestWithMapRect:mapRect
                                zoomScale:zoomScale
                                   region:MKCoordinateRegionForMapRect(mapRect)];
    }

    return image != nil;
}

/**
 Draws the contents of the overlay view.
 */
- (void)drawMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale inContext:(CGContextRef)context 
{   
    UIImage *imageData = [tiler getImageForMapRect:mapRect zoomScale:zoomScale];

    if (imageData) {
        UIGraphicsPushContext(context); 

        CGRect drawRect = [self rectForMapRect:mapRect];
        CGContextDrawImage(context, drawRect, imageData.CGImage);

        UIGraphicsPopContext();
    }
    
}

@end
