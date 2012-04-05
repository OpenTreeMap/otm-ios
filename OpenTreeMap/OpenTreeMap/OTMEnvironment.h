/*

 OTMEnvironment.h

 Created by Justin Walgran on 2/22/12.

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

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "OTMAPI.h"

/**
 An interface to global application settings that may change for each build configuration (i.e. Debug, Release)
 */
@interface OTMEnvironment : NSObject {
    /**
     The name given to the shared TTURLCache
     */
    NSString *urlCacheName;

    /**
     The maximum number of queue items allowed in the shared TTURLRequestQueue
     */
    NSNumber *urlCacheQueueMaxContentLength;

    /**
     The number of seconds that an object in the shared cache will be considered 'fresh'
     */
    NSNumber *urlCacheInvalidationAgeInSeconds;

    /**
     The initial map view extent displayed when the application is first loaded
     */
    MKCoordinateRegion mapViewInitialCoordinateRegion;

    /**
     The coordinate span to use when zooming to an address search result
     */
    MKCoordinateSpan mapViewSearchZoomCoordinateSpan;

    /**
     The GeoServer WMS endpoint url from which map tiles will be requested
     */
    NSString *geoServerWMSServiceURL;

    /**
     The names of the GeoServer layers that are composited to produce map tiles
     */
    NSArray *geoServerLayerNames;

    /**
     The image format in which image tiles should be requested
     */
    NSString *geoServerFormat;
}

/**
 Accesses the single shared OTMEnvironment instance for the application
 */
+ (id)sharedEnvironment;

// Environment properties
@property (nonatomic, retain) NSString *urlCacheName;
@property (nonatomic, retain) NSNumber *urlCacheQueueMaxContentLength;
@property (nonatomic, retain) NSNumber *urlCacheInvalidationAgeInSeconds;

// Implementation properties
@property (nonatomic, assign) MKCoordinateRegion mapViewInitialCoordinateRegion;
@property (nonatomic, assign) MKCoordinateSpan mapViewSearchZoomCoordinateSpan;
@property (nonatomic, retain) NSString *geoServerWMSServiceURL;
@property (nonatomic, retain) NSArray *geoServerLayerNames;
@property (nonatomic, retain) NSString *geoServerFormat;
@property (nonatomic, copy) NSString* baseURL;
@property (nonatomic, copy) NSString* apiKey;

// Derived Properties
@property (nonatomic, strong) OTMAPI* api;

@end
