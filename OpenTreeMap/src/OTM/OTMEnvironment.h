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
@property (nonatomic, strong) NSString *detailUnit;

@property (nonatomic, strong) AZHttpRequest *tileRequest;

// Choices values
@property (nonatomic, retain) NSDictionary* choices;

// Derived Properties
@property (nonatomic, strong) OTMAPI* api;

@end
