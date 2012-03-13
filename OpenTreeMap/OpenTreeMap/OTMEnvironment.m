/*

 OTMEnvironment.m

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
#import "OTMEnvironment.h"
#import "AZHttpRequest.h"

@implementation OTMEnvironment

@synthesize urlCacheName, urlCacheQueueMaxContentLength, urlCacheInvalidationAgeInSeconds, mapViewInitialCoordinateRegion, geoServerWMSServiceURL, geoServerLayerNames, geoServerFormat, api, baseURL, apiKey;

+ (id)sharedEnvironment
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

/**
 Initialize the OTMEnvironment by reading values from the appropriate plist file.
 Expects that info.plist contains a 'Configuration' key.
 */
- (id)init
{
    self = [super init];
    if (!self) { return nil; }

    // Environment

    NSString* configuration = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"Configuration"];
    NSBundle* bundle = [NSBundle mainBundle];
    NSString* environmentPListPath = [bundle pathForResource:configuration ofType:@"plist"];
    NSDictionary* environment = [[NSDictionary alloc] initWithContentsOfFile:environmentPListPath];

    // Environment - URLCache

    NSDictionary *urlCache = [environment valueForKey:@"URLCache"];

    [self setUrlCacheName:[urlCache valueForKey:@"Name"]];
    [self setUrlCacheQueueMaxContentLength:[urlCache valueForKey:@"QueueMaxContentLength"]];
    [self setUrlCacheInvalidationAgeInSeconds:[urlCache valueForKey:@"InvalidationAgeInSeconds"]];

    // Implementation

    NSString* implementationPListPath = [bundle pathForResource:@"Implementation" ofType:@"plist"];
    NSDictionary* implementation = [[NSDictionary alloc] initWithContentsOfFile:implementationPListPath];
    
    self.apiKey = [implementation valueForKey:@"APIKey"];

    NSDictionary* url = [implementation valueForKey:@"APIURL"];
    
    [self setBaseURL:[NSString stringWithFormat:@"%@/%@/",
                      [url valueForKey:@"base"],
                      [url valueForKey:@"version"]]];
    
    // Implementation - GeoServer

    NSDictionary *geoServer = [implementation valueForKey:@"GeoServer"];

    [self setGeoServerWMSServiceURL:[geoServer valueForKey:@"WMSServiceURL"]];
    [self setGeoServerLayerNames:[[geoServer valueForKey:@"LayerNames"] componentsSeparatedByString:@","]];
    [self setGeoServerFormat:[geoServer valueForKey:@"Format"]];

    // Implementation - MapView

    NSDictionary *mapView = [implementation valueForKey:@"MapView"];

    CLLocationCoordinate2D initialLatLon = CLLocationCoordinate2DMake(
        [[mapView objectForKey:@"InitialLatitude"] floatValue],
        [[mapView objectForKey:@"InitialLongitude"] floatValue]);

    MKCoordinateSpan initialCoordinateSpan = MKCoordinateSpanMake(
        [[mapView objectForKey:@"InitialLatitudeDelta"] floatValue],
        [[mapView objectForKey:@"InitialLongitudeDelta"] floatValue]);

    [self setMapViewInitialCoordinateRegion:MKCoordinateRegionMake(initialLatLon, initialCoordinateSpan)];

    OTMAPI* otmApi = [[OTMAPI alloc] init];
    AZHttpRequest* req = [[AZHttpRequest alloc] initWithURL:[self baseURL]];
    req.headers = [NSDictionary dictionaryWithObjectsAndKeys:self.apiKey, @"X-API-Key", nil];

    otmApi.request = req;
    
    self.api = otmApi;
    
    return self;
}


@end
