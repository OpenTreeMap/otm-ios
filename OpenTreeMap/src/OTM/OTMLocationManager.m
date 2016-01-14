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

#import "OTMLocationManager.h"

@implementation OTMLocationManager

- (id)init
{
    return [self initWithDistanceRestriction:YES];
}

- (id)initWithDistanceRestriction:(BOOL)rd
{
    self = [super init];
    if (self) {
        [self setRestrictDistance:rd];
    }
    return self;
}

- (BOOL)locationServicesAvailable
{
    return [CLLocationManager locationServicesEnabled] && [CLLocationManager authorizationStatus]!=kCLAuthorizationStatusDenied;
}

- (void)findLocation:(void(^)(CLLocation*, NSError*))callback
{
    [self findLocationWithAccuracy:kCLLocationAccuracyHundredMeters callback:callback];
}

- (void)findLocationWithAccuracy:(CLLocationAccuracy)accuracy callback:(void(^)(CLLocation*, NSError*))callback;
{
    if (callback == nil) {
        return;
    }
    if ([self locationServicesAvailable]) {

        if (nil == [self locationManager]) {
            [self setLocationManager:[[CLLocationManager alloc] init]];
            [[self locationManager] setDesiredAccuracy:accuracy];
        }

        [self setLocationFoundCallback:callback];

        // The delegate is cleared in stopFindingLocation so it must be reset
        // here.
        [[self locationManager] setDelegate:self];

        // Required to get iOS8 location services to run.
        if ([[self locationManager] respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            [[self locationManager] requestWhenInUseAuthorization];
            [[self locationManager] startUpdatingLocation];
        } else {
            [[self locationManager] startUpdatingLocation];
        }

        NSTimeInterval timeout = [[[OTMEnvironment sharedEnvironment] locationSearchTimeoutInSeconds] doubleValue];
        [self performSelector:@selector(stopFindingLocationAndExecuteCallback) withObject:nil afterDelay:timeout];
    } else {
        // TODO: More meaningful error
        NSError* error = [[NSError alloc] initWithDomain:@"otm"
                                                    code:-1
                                                userInfo:nil];
        callback(nil, error);
    }
}

- (void)stopFindingLocation
{
    [[self locationManager] stopUpdatingLocation];
    // When using the debugger I found that extra events would arrive after
    // calling stopUpdatingLocation. Setting the delegate to nil ensures that
    // those events are not ignored.
    [[self locationManager] setDelegate:nil];
}


- (void)stopFindingLocationAndExecuteCallback
{
    if ([[self locationManager] delegate]) {
        [self stopFindingLocation];
        if ([self mostAccurateLocationResponse] != nil) {
            CLLocation *loc = [self mostAccurateLocationResponse];

            OTMEnvironment *env = [OTMEnvironment sharedEnvironment];
            CLLocationCoordinate2D center = env.mapViewInitialCoordinateRegion.center;
            CLLocationDistance dist = [loc distanceFromLocation:[[CLLocation alloc] initWithLatitude:center.latitude longitude:center.longitude]];

            if (dist < [env searchRegionRadiusInMeters]) {
                // Call something
            }
        } else {
            // TODO: More meaningful error
            NSError* error = [[NSError alloc] initWithDomain:@"otm"
                                                        code:-1
                                                    userInfo:nil];

            [self locationFoundCallback](nil, error);
        }
        [self setMostAccurateLocationResponse:nil];
    }
}

#pragma mark CoreLocation delegate

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    NSDate* eventDate = newLocation.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    // Avoid using any cached location results by making sure they are less than
    // 15 seconds old
    if (abs(howRecent) < 15.0)
    {
        NSLog(@"Location accuracy: horizontal %f, vertical %f", [newLocation horizontalAccuracy], [newLocation verticalAccuracy]);

        if ([self mostAccurateLocationResponse] == nil || [[self mostAccurateLocationResponse] horizontalAccuracy] > [newLocation horizontalAccuracy]) {
            [self setMostAccurateLocationResponse: newLocation];
        }

        if ([newLocation horizontalAccuracy] > 0 && [newLocation horizontalAccuracy] < [manager desiredAccuracy]) {
            [self stopFindingLocation];
            [self setMostAccurateLocationResponse:nil];
            // Cancel the previous performSelector:withObject:afterDelay: - it's
            // no longer necessary
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stopFindingLocation:) object:nil];

            NSLog(@"Found user's location: latitude %+.6f, longitude %+.6f\n",
                  newLocation.coordinate.latitude,
                  newLocation.coordinate.longitude);

            OTMEnvironment *env = [OTMEnvironment sharedEnvironment];
            CLLocationCoordinate2D center = env.mapViewInitialCoordinateRegion.center;
            CLLocationDistance dist = [newLocation distanceFromLocation:[[CLLocation alloc] initWithLatitude:center.latitude longitude:center.longitude]];

            if (![self restrictDistance] || dist < [env searchRegionRadiusInMeters]) {
                [self locationFoundCallback](newLocation, nil);
            }
        }
    }
}

@end
