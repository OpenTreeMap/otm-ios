//
//  OTMGeocodeOperation.m
//  OpenTreeMap
//
//  Created by Justin Walgran on 4/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OTMReverseGeocodeOperation.h"

@implementation OTMReverseGeocodeOperation

@synthesize location, callback;

static CLGeocoder *geocoder;

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate callback:(CLGeocodeCompletionHandler)aCallback
{
    return [self initWithLocation:[[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude] callback:aCallback];
}

- (id)initWithLocation:(CLLocation *)aLocation
     callback:(CLGeocodeCompletionHandler)aCallback;
{
    self = [super init];
    if (self) {
        if (!geocoder) {
            geocoder = [[CLGeocoder alloc] init];
        }             
        self.location = aLocation;
        self.callback = aCallback;
    }
    return self;
}

- (void)main 
{
    [geocoder reverseGeocodeLocation:self.location completionHandler:self.callback];
}

@end
