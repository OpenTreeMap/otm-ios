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
     A string that is appended to the text that the user exters into the map
     view search bar before being submitted to the API for geocoding
     */
    NSString *searchSuffix;

    /**
     The number of seconds to wait for CoreLocation to find the users postion
     at the desired accuracy.
     */
    NSNumber *locationSearchTimeoutInSeconds;

    /**
     The text on the main map view navigation bar
     */
    NSString *mapViewTitle;
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
@property (nonatomic, copy) NSString* searchSuffix;
@property (nonatomic, retain) NSNumber *locationSearchTimeoutInSeconds;
@property (nonatomic, copy) NSString* mapViewTitle;

@property (nonatomic, copy) NSString* baseURL;
@property (nonatomic, copy) NSString* apiKey;

@property (nonatomic, strong) NSArray *filters;

@property (nonatomic, strong) NSArray *fieldKeys;
@property (nonatomic, strong) UIColor *viewBackgroundColor;
@property (nonatomic, strong) UIColor *navBarTintColor;
@property (nonatomic, strong) UIImage *buttonImage;
@property (nonatomic, strong) UIColor *buttonTextColor;
@property (nonatomic, assign) BOOL pendingActive;
@property (nonatomic, strong) NSArray* fieldSections;
@property (nonatomic, strong) NSDictionary* fields;
@property (nonatomic, strong) NSArray* filts;
@property (nonatomic, assign) BOOL useOtmGeocoder;
@property (nonatomic, assign) double searchRegionRadiusInMeters;
@property (nonatomic, assign) float splashDelayInSeconds;
@property (nonatomic, assign) BOOL hideTreesFilter;

@property (nonatomic, strong) AZHttpRequest *tileRequest;

// Choices values
@property (nonatomic, retain) NSDictionary* choices;

// Derived Properties
@property (nonatomic, strong) OTMAPI* api;

@end
