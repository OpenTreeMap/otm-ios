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

#import "AZWMSOverlayView.h"
#import "AZWMSOverlay.h"

@implementation AZWMSOverlayView

/**
 Send an asynchronous request to the WMS server to fetch a map tile image
 @param url The url to be opened
 @param mapRect The extent of the map tile being requested
 @param zoomScale The ratio of pixels to map units for the reqested map tile
 */
/*
- (void)sendTileRequestWithUrl:(NSString *)url mapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale 
{
    TTURLRequest *request = [TTURLRequest requestWithURL:url delegate:self];
 
    // Provide extra info to the delegate method so that it can correctly call setNeedsDisplayInMapRect:zoomScale:
    request.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                        [NSNumber numberWithDouble:mapRect.origin.x], @"mapRect_origin_x",
                        [NSNumber numberWithDouble:mapRect.origin.y], @"mapRect_origin_y",
                        [NSNumber numberWithDouble:mapRect.size.width], @"mapRect_size_width",
                        [NSNumber numberWithDouble:mapRect.size.height], @"mapRect_size_height",
                        [NSNumber numberWithFloat:zoomScale], @"zoomScale",
                        nil];  
    
    request.response = [[TTURLDataResponse alloc] init];
    request.cachePolicy = TTURLRequestCachePolicyLocal;
    
    // The request must be sent on the main thread in order to correctly return
    [request performSelectorOnMainThread:@selector(send) withObject:nil waitUntilDone:NO];
}
*/
#pragma mark MKOverlayView methods

/**
 Returns a Boolean value indicating whether the overlay view is ready to draw its content.
 */
/*
- (BOOL)canDrawMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale 
{
    AZWMSOverlay *wmsOverlay = (AZWMSOverlay *)[self overlay];
    NSString *urlString = [wmsOverlay getMapRequstUrlForMapRect:mapRect zoomScale:zoomScale];

    TTURLCache *cache = [TTURLCache sharedCache];
    if ([cache hasDataForURL:urlString]) {
        return YES;
    } else {
        // If the cache does not have a tile for the requested URL, start a new request in the backround and
        // return NO to let the caller know that the tile is not yet loaded.
        [self sendTileRequestWithUrl:urlString mapRect:mapRect zoomScale:zoomScale];
        return NO;
    }
}
 */

/**
 Draws the contents of the overlay view.
 */
/*
- (void)drawMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale inContext:(CGContextRef)context 
{
    AZWMSOverlay *wmsOverlay = (AZWMSOverlay *)[self overlay];
    NSString *urlString = [wmsOverlay getMapRequstUrlForMapRect:mapRect zoomScale:zoomScale];
    
    TTURLCache *cache = [TTURLCache sharedCache];
    NSData *imageData = [cache dataForURL:urlString];
    if (imageData != nil) {
        UIImage *img = [UIImage imageWithData:imageData];
        // Perform the image render on the current UI context
        UIGraphicsPushContext(context);
        [img drawInRect:[self rectForMapRect:mapRect] blendMode:kCGBlendModeNormal alpha:1];
        UIGraphicsPopContext();
    }
}
*/
#pragma mark TTURLRequestDelegate methods

/**
 Called when the request has loaded data and been processed into a response.
 */
/*
-(void)requestDidFinishLoad:(TTURLRequest *)request {
    NSNumber *mapRect_origin_x = [(NSDictionary *)[request userInfo] objectForKey:@"mapRect_origin_x"];
    NSNumber *mapRect_origin_y = [(NSDictionary *)[request userInfo] objectForKey:@"mapRect_origin_y"];
    NSNumber *mapRect_size_width = [(NSDictionary *)[request userInfo] objectForKey:@"mapRect_size_width"];
    NSNumber *mapRect_size_height = [(NSDictionary *)[request userInfo] objectForKey:@"mapRect_size_height"];
    
    MKMapRect mapRect = MKMapRectMake([mapRect_origin_x doubleValue],
                                      [mapRect_origin_y doubleValue],
                                      [mapRect_size_width doubleValue],
                                      [mapRect_size_height doubleValue]);
    
    NSNumber *zoomScaleNumber = [(NSDictionary *)[request userInfo] objectForKey:@"zoomScale"];
    MKZoomScale zoomScale = [zoomScaleNumber floatValue];
    
    // "Invalidate" the image at the mapRect which triggers MapKit to attempt another load for the tile. Because
    // the tile is now in the cache, canDrawMapRect:zoomScale: should now return YES.
    [self setNeedsDisplayInMapRect:mapRect zoomScale:zoomScale];
}
 */

@end
