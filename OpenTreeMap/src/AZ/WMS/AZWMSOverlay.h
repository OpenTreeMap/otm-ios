/*
 
 AZWMSOverlay.h
 
 Created by Justin Walgran on 2/21/12.
 
 License
 =======
 Copyright (c) 2012 Azavea. All rights reserved.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
 documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
 rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit
 persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
 Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
 WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
 OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 */

#import <MapKit/MapKit.h>

/**
 A MapKit overlay for dispalying map images from a WMS server loaded via HTTP
 */
@interface AZWMSOverlay : NSObject <MKOverlay> {
    /**
     The WMS service endpoint URL
     */
    NSString *serviceUrl;
    
    /**
     An array of layer names that will be combined in the layered map image
     */
    NSArray *layerNames;
    
    /**
     An array of style names that will be matched to each of the specified layers
     */
    NSArray *styleNames;
    
    /**
     The WMS API version. 
     Defaults to '1.1.0'
     */
    NSString *version;
    
    /**
     Sets whether or not the WMS server should produce images with transparency. 
     Defaults to YES
     */
    BOOL requestTilesWithTransparency;
    
    /**
     A value between 0.0 and 1.0 that sets the opacity of the map images when they are rendered over the base map.
     Defaults to 1.0
     */
    float opacity;

    /**
     The image format for map tiles requested from the WMS server
     Defaults to image/png
     */
    NSString *format;
}

@property (nonatomic, retain) NSString *serviceUrl;
@property (nonatomic, retain) NSArray *layerNames;
@property (nonatomic, retain) NSArray *styleNames;
@property (nonatomic, retain) NSString *version;
@property (nonatomic, assign) BOOL requestTilesWithTransparency;
@property (nonatomic, assign) float opacity;
@property (nonatomic, retain) NSString *format;

/**
 Create a WMS GetMap request URL that corresponds to a given MKMapRect and MKZoomScale
 @param mapRect The extent of the map to be requested
 @param zoomScale The ratio of pixels to map units
 @returns A URL string that requests an image from a WMS server
 */
- (NSString *)getMapRequstUrlForMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale;

@end
