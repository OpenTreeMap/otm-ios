//
//  OTMGeocodeOperation.h
//  OpenTreeMap
//
//  Created by Justin Walgran on 4/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface OTMReverseGeocodeOperation : NSOperation

@property (nonatomic, strong) CLLocation *location;
@property (nonatomic, strong) CLGeocodeCompletionHandler callback;

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate callback:(CLGeocodeCompletionHandler)aCallback;

- (id)initWithLocation:(CLLocation *)aLocation 
     callback:(CLGeocodeCompletionHandler)aCallback;

@end
