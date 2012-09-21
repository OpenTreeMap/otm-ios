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
#import "AZMapHelper.h"

@implementation AZMapHelper

+ (CLLocationCoordinate2D)CLLocationCoordinate2DMakeWithDictionary:(NSDictionary *)dict
{
    double lon;
    double lat;

    if ([dict objectForKey:@"lng"]) {
        lon = [[dict objectForKey:@"lng"] doubleValue];
    } else if ([dict objectForKey:@"lon"]) {
        lon = [[dict objectForKey:@"lon"] doubleValue];
    } else if ([dict objectForKey:@"x"]) {
        lon = [[dict objectForKey:@"x"] doubleValue];
    } else {
        [NSException raise:NSInvalidArgumentException format:@"The dictionary does not contatin a 'lon', 'lng', or 'x' key."];
    }
    
    if ([dict objectForKey:@"lat"]) {
        lat = [[dict objectForKey:@"lat"] doubleValue];
    } else if ([dict objectForKey:@"y"]) {
        lat = [[dict objectForKey:@"y"] doubleValue];
    } else {
        [NSException raise:NSInvalidArgumentException format:@"The dictionary does not contatin a 'lat' or 'y' key."];
    }
    
    return CLLocationCoordinate2DMake(lat, lon);
}

@end
