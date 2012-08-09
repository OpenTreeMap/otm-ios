/*

 OTMEnvironment.m

 Created by Justin Walgran on 2/22/12.

 License
 =======
 Copyright (c) 2012 Azavea. All rights reserved.

 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

 */
#import "OTMEnvironment.h"
#import "AZHttpRequest.h"
#import "OTMDetailCellRenderer.h"
#import "OTMFilterListViewController.h"

@implementation OTMEnvironment

@synthesize urlCacheName, urlCacheQueueMaxContentLength, urlCacheInvalidationAgeInSeconds, mapViewInitialCoordinateRegion, mapViewSearchZoomCoordinateSpan, searchSuffix, locationSearchTimeoutInSeconds, mapViewTitle, api, baseURL, apiKey, choices, fieldKeys, viewBackgroundColor, navBarTintColor, buttonImage, buttonTextColor, filters, pendingActive, fields, filts, useOtmGeocoder, searchRegionRadiusInMeters, tileRequest;

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
    NSString *choicesPListPath = [bundle pathForResource:@"Choices" ofType:@"plist"];
    NSDictionary* environment = [[NSDictionary alloc] initWithContentsOfFile:environmentPListPath];

    choices = [[NSDictionary alloc] initWithContentsOfFile:choicesPListPath];
    
    // Environment - URLCache

    NSDictionary *urlCache = [environment valueForKey:@"URLCache"];

    [self setUrlCacheName:[urlCache valueForKey:@"Name"]];
    [self setUrlCacheQueueMaxContentLength:[urlCache valueForKey:@"QueueMaxContentLength"]];
    [self setUrlCacheInvalidationAgeInSeconds:[urlCache valueForKey:@"InvalidationAgeInSeconds"]];

    // Implementation

    NSString* implementationPListPath = [bundle pathForResource:@"Implementation" ofType:@"plist"];
    NSDictionary* implementation = [[NSDictionary alloc] initWithContentsOfFile:implementationPListPath];
    
    self.apiKey = [implementation valueForKey:@"APIKey"];
    
    fields = [implementation objectForKey:@"fields"];
    filts = [implementation objectForKey:@"filters"];

    pendingActive = [[implementation valueForKey:@"pending"] boolValue];

    viewBackgroundColor = [self colorFromArray:[implementation objectForKey:@"backgroundColor"] defaultColor:[UIColor whiteColor]];
    
    navBarTintColor = [self colorFromArray:[implementation objectForKey:@"tintColor"] defaultColor:nil];    
    
    buttonTextColor = [self colorFromArray:[implementation objectForKey:@"buttonFontColor"] defaultColor:[UIColor whiteColor]];
    
    buttonImage = [UIImage imageNamed:@"btn_bg"];    

    NSDictionary* url = [implementation valueForKey:@"APIURL"];
    
    [self setBaseURL:[NSString stringWithFormat:@"%@/%@/",
                      [url valueForKey:@"base"],
                      [url valueForKey:@"version"]]];

    // Implementation - MapView

    NSDictionary *mapView = [implementation valueForKey:@"MapView"];

    CLLocationCoordinate2D initialLatLon = CLLocationCoordinate2DMake(
        [[mapView objectForKey:@"InitialLatitude"] floatValue],
        [[mapView objectForKey:@"InitialLongitude"] floatValue]);

    MKCoordinateSpan initialCoordinateSpan = MKCoordinateSpanMake(
        [[mapView objectForKey:@"InitialLatitudeDelta"] floatValue],
        [[mapView objectForKey:@"InitialLongitudeDelta"] floatValue]);

    [self setMapViewInitialCoordinateRegion:MKCoordinateRegionMake(initialLatLon, initialCoordinateSpan)];

    MKCoordinateSpan searchZoomCoordinateSpan = MKCoordinateSpanMake(
        [[mapView objectForKey:@"SearchZoomLatitudeDelta"] floatValue],
        [[mapView objectForKey:@"SearchZoomLongitudeDelta"] floatValue]);

    [self setMapViewSearchZoomCoordinateSpan:searchZoomCoordinateSpan];

    [self setUseOtmGeocoder:[[mapView valueForKey:@"UseOtmGeocoder"] boolValue]];

    [self setSearchRegionRadiusInMeters:[[mapView valueForKey:@"SearchRegionRadiusInMeters"] doubleValue]];

    [self setSearchSuffix:[mapView valueForKey:@"SearchSuffix"]];

    [self setLocationSearchTimeoutInSeconds:[mapView valueForKey:@"LocationSearchTimeoutInSeconds"]];

    [self setMapViewTitle:[mapView valueForKey:@"MapViewTitle"]];

    OTMAPI* otmApi = [[OTMAPI alloc] init];
    
    NSString* versionPlistPath = [bundle pathForResource:@"version" ofType:@"plist"];
    NSDictionary* version = [[NSDictionary alloc] initWithContentsOfFile:versionPlistPath];
    NSString *ver = [NSString stringWithFormat:@"ios-%@-b%@",
                         [version objectForKey:@"version"],
                         [version objectForKey:@"build"]];

    // Note: treq is used for tile requests, this prevents the main
    // operation queue from overloading with tiles
    NSDictionary *headers = [NSDictionary dictionaryWithObjectsAndKeys:self.apiKey, @"X-API-Key", 
                                          ver, @"ApplicationVersion",
                                          nil];

    AZHttpRequest* req = [[AZHttpRequest alloc] initWithURL:[self baseURL]];
    req.headers = headers;
    AZHttpRequest* treq = [[AZHttpRequest alloc] initWithURL:[self baseURL]];
    treq.headers = headers;
    treq.synchronous = YES;

    req.queue.maxConcurrentOperationCount = 3;
    treq.queue.maxConcurrentOperationCount = 1;
    
    otmApi.request = req;
    otmApi.tileRequest = treq;

    self.tileRequest = treq;    
    self.api = otmApi;
    
    return self;
}

-(UIColor *)colorFromArray:(NSArray *)array defaultColor:(UIColor *)c {
    if (array == nil || [array count] != 4) {
        return c;
    } else {
        return [UIColor colorWithRed:[[array objectAtIndex:0] floatValue]
                               green:[[array objectAtIndex:1] floatValue]
                                blue:[[array objectAtIndex:2] floatValue]
                               alpha:[[array objectAtIndex:3] floatValue]];
    }
}

-(NSArray *)filters {
    NSMutableArray* fs = [NSMutableArray array];
    for(NSDictionary *f in filts) {
        [fs addObject:[OTMFilter filterFromDictionary:f]];
    }

    return fs;
}

-(NSArray *)fieldKeys {
    return fields;
}


@end
