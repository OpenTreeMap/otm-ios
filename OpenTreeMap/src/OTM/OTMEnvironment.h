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
#import "OTM2API.h"
#import "OTMFormatter.h"

#define kOTMEnvironmentChangeNotification @"kOTMEnvironmentChangeNotification"
#define kOTMGeoRevChangeNotification @"kOTMGeoRevChangeNotification"

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
@property (nonatomic, copy) NSString* tilerUrl;

@property (nonatomic, strong) NSArray *filters;

@property (nonatomic, strong) NSArray *fieldKeys;
@property (nonatomic, strong) UIColor *primaryColor;
@property (nonatomic, strong) UIColor *secondaryColor;
@property (nonatomic, strong) UIColor *viewBackgroundColor;
@property (nonatomic, strong) UIImage *buttonImage;
@property (nonatomic, strong) UIColor *buttonTextColor;
@property (nonatomic, assign) BOOL pendingActive;
@property (nonatomic, strong) NSArray *sectionTitles;
@property (nonatomic, strong) NSArray *fields;
@property (nonatomic, strong) NSDictionary *sortKeys;
@property (nonatomic, strong) NSArray *ecoFields;
@property (nonatomic, strong) NSArray *filts;
@property (nonatomic, assign) BOOL useOtmGeocoder;
@property (nonatomic, assign) double searchRegionRadiusInMeters;
@property (nonatomic, strong) NSString *tileQueryStringAdditionalArguments;
@property (nonatomic, assign) double nearbyTreeRadiusInMeters;
@property (nonatomic, assign) double recentEditsRadiusInMeters;
@property (nonatomic, assign) float splashDelayInSeconds;
@property (nonatomic, strong) NSString *distanceUnit;
@property (nonatomic) double distanceBiggerUnitFactor;
@property (nonatomic) double distanceFromMetersFactor;
@property (nonatomic, strong) NSString *distanceBiggerUnit;
@property (nonatomic, strong) NSString *dateFormat;
@property (nonatomic, strong) NSString *currencyUnit;
@property (nonatomic) double detailLatSpan;
@property (nonatomic) UIKeyboardType zipcodeKeyboard;

@property (nonatomic, strong) AZHttpRequest *tileRequest;

// Derived Properties
@property (nonatomic, strong) OTMAPI* api;
@property (nonatomic, strong) OTM2API* api2;

// OTM2 props
@property (nonatomic, strong) NSString* instance;
@property (nonatomic, assign) BOOL allowInstanceSwitch;
@property (nonatomic, strong) NSString* instanceId;
@property (nonatomic, strong) NSString* geoRev;
@property (nonatomic, strong) NSString* host;
@property (nonatomic, strong) OTMFormatter* dbhFormat;
@property (nonatomic, strong) NSDictionary* config;
@property (nonatomic, strong) NSURL *instanceLogoUrl;
@property BOOL speciesFieldWritable;
@property BOOL photoFieldWritable;


// Security
@property (nonatomic, strong) NSString *secretKey;
@property (nonatomic, strong) NSString *accessKey;

// User generated content
@property (nonatomic, strong) NSString *inappropriateReportEmail;


- (void)updateEnvironmentWithDictionary:(NSDictionary *)dict;


- (NSString *)absolutePhotoUrlFromPhotoUrl:(NSString *)url;

- (BOOL) speciesFieldIsWritable;
- (BOOL) photoFieldIsWritable;

@end
