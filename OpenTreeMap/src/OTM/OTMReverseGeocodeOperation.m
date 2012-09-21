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
