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

#import "AZPointOffsetOverlayView.h"
#import "AZPointOffsetOverlay.h"

@implementation AZPointOffsetOverlayView

@synthesize renderedImageCache, tileAlpha, pointStamp;

- (id)initWithOverlay:(id<MKOverlay>)overlay {
    if (self = [super initWithOverlay:overlay]) {
        renderedImageCache = [[NSMutableDictionary alloc] init];
        self.pointStamp = [UIImage imageNamed:@"tree_icon"];
        self.tileAlpha = 1.0f;
        self.clipsToBounds = NO;
    }
    
    return self;
}

-(NSString*)getCacheKeyForMapRect:(MKMapRect)mapRect {
    return [NSString stringWithFormat:@"%f,%f,%f,%f", mapRect.origin.x, mapRect.origin.y, mapRect.size.width, mapRect.size.width];
}

/**
 Send an asynchronous request to a server that returns a point offset 'tile' then render those point offsets to an image and then notify MapKit that the region is ready to be redrawn.
 @param url The url to be opened
 @param mapRect The extent of the map tile being requested
 @param zoomScale The ratio of pixels to map units for the reqested map tile
 */
- (void)sendTileRequestWithMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale 
{    
    NSString* key = [self getCacheKeyForMapRect:mapRect];
    
    __block AZPointOffsetOverlayView *blockSelf = self;
    
    [[[OTMEnvironment sharedEnvironment] api] getPointOffsetsInTile:MKCoordinateRegionForMapRect(mapRect) callback:
     ^(CFArrayRef points, NSError* error) {
         if (error == nil) {
             UIImage* image = [AZPointOffsetOverlayView createImageWithOffsets:points stamp:[self pointStamp] alpha:tileAlpha];
             
             [renderedImageCache setObject:image forKey:key];
             dispatch_async(dispatch_get_main_queue(), 
                            ^{
                                [blockSelf setNeedsDisplayInMapRect:mapRect zoomScale:zoomScale];         
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
    NSString* key = [self getCacheKeyForMapRect:mapRect];
    if ([renderedImageCache objectForKey:key] != nil) {
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
    UIGraphicsBeginImageContext(CGSizeMake(256, 256));
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(context);
    
    CGContextSetFillColorWithColor(context, [[UIColor blackColor] CGColor]);
    
    CGRect baseRect = CGRectMake(-imageSize.width / 2.0f, 
                                 -imageSize.height / 2.0f, 
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

/**
 Draws the contents of the overlay view.
 */
- (void)drawMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale inContext:(CGContextRef)context 
{   
    NSString* key = [NSString stringWithFormat:@"%f,%f,%f,%f", mapRect.origin.x, mapRect.origin.y, mapRect.size.width, mapRect.size.width];
    
    CGRect drawRect = [self rectForMapRect:mapRect];
    
    UIGraphicsPushContext(context);
    
    UIImage* imageData = [renderedImageCache objectForKey:key];
    [imageData drawInRect:drawRect blendMode:kCGBlendModeNormal alpha:1];
    
    UIGraphicsPopContext();
}

@end
