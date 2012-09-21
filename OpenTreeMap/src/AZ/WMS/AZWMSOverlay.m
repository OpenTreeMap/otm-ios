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
