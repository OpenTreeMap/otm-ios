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

#import "OTMTreeDictionaryHelper.h"

@implementation OTMTreeDictionaryHelper

+(NSMutableDictionary *)setCoordinate:(CLLocationCoordinate2D)coordinate inDictionary:(NSMutableDictionary *)dict
{
    NSMutableDictionary *geometryDict = [dict objectForKey:@"geometry"];

    [geometryDict setValue:[NSNumber numberWithFloat:coordinate.latitude] forKey:@"lat"];

    if ([geometryDict objectForKey:@"lon"]) {
        [geometryDict setValue:[NSNumber numberWithFloat:coordinate.longitude] forKey:@"lon"];
    } else {
        [geometryDict setValue:[NSNumber numberWithFloat:coordinate.longitude] forKey:@"lng"];
    }

    return dict;
}

+(CLLocationCoordinate2D)getCoordinateFromDictionary:(NSDictionary *)dict
{
    NSDictionary *geometryDict = [dict objectForKey:@"geom"];

    float lat = [[geometryDict objectForKey:@"y"] floatValue];
    float lng = [[geometryDict objectForKey:@"x"] floatValue];

    return CLLocationCoordinate2DMake(lat, lng);
}


@end
