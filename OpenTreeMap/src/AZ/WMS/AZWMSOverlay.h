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
