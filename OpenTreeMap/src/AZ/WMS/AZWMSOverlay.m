/*
 
 AZWMSOverlay.m
 
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

#import "AZWMSOverlay.h"

@implementation AZWMSOverlay

@synthesize boundingMapRect; // from <MKOverlay>
@synthesize coordinate;      // from <MKOverlay>

@synthesize serviceUrl, layerNames, styleNames, version, requestTilesWithTransparency, opacity, format;

/**
 Initialize an AZWMSOverlay with default values for the version, opacity, requestTilesWithTransparency
 layerNames, and styleNames properties.
 */
-(id) init {
    self = [super init];
    if (!self) { return nil; }
    
    /*
     
     A comment from https://github.com/mtigas/iOS-MapLayerDemo

     "The Google Mercator projection is slightly off from the "standard" Mercator projection, used by MapKit.
     My understanding is that this is due to Google Maps' use of a Spherical Mercator
     projection, where the poles are cut off -- the effective map ending at approx. +/- 85º.
     MapKit does not(?), therefore, our origin point (top-left) must be moved accordingly."
    
     */
    boundingMapRect = MKMapRectWorld;
    boundingMapRect.origin.x += 1048600.0;
    boundingMapRect.origin.y += 1048600.0;
    
    coordinate = CLLocationCoordinate2DMake(0, 0);
    
    [self setVersion:@"1.1.0"];
    [self setOpacity:1.0];
    [self setRequestTilesWithTransparency:YES];
    [self setLayerNames:[[NSArray alloc] init]];
    [self setStyleNames:[[NSArray alloc] init]];
    [self setFormat:@"image/png"];
    
    return self;
} 

- (NSString *)getMapRequstUrlForMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale
{
    MKCoordinateRegion region = MKCoordinateRegionForMapRect(mapRect);
    
    float bbox0 = region.center.longitude - (region.span.longitudeDelta/2);
    float bbox1 = region.center.latitude - (region.span.latitudeDelta/2);
    float bbox2 = bbox0 + region.span.longitudeDelta;
    float bbox3 = bbox1 + region.span.latitudeDelta;
    
    int width = (int)(mapRect.size.width * zoomScale);
    int height = (int)(mapRect.size.width * zoomScale);
    
    NSString *layersString = [[self layerNames] componentsJoinedByString:@","];
    
    NSString *transparentString;
    if ([self requestTilesWithTransparency]) {
        transparentString = @"true";
    } else {
        transparentString = @"false";
    }
    
    NSString *url = [NSString stringWithFormat:@"%@?service=WMS&version=%@&request=GetMap&layers=%@&styles=&bbox=%f,%f,%f,%f&width=%d&height=%d&srs=EPSG:4326&format=%@&transparent=%@", [self serviceUrl], [self version],layersString, bbox0, bbox1, bbox2, bbox3, width, height, [self format], transparentString];
    
    NSString *escapedUrl = [url stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];

    return  escapedUrl;
}

@end
