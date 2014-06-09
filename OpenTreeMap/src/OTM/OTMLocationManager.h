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
#import <CoreLocation/CoreLocation.h>

@interface OTMLocationManager : NSObject <CLLocationManagerDelegate>

@property (nonatomic,strong) CLLocationManager *locationManager;
@property (nonatomic,strong) CLLocation *mostAccurateLocationResponse;
@property (nonatomic,assign) BOOL restrictDistance;

@property (nonatomic,copy) void (^locationFoundCallback)(CLLocation*, NSError*);

- (id)initWithDistanceRestriction:(BOOL)rd;
- (void)findLocation:(void(^)(CLLocation *location, NSError *error))callback;
- (void)stopFindingLocation;
- (BOOL)locationServicesAvailable;

@end