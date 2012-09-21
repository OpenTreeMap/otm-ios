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

@interface AZMapHelper : NSObject

/*

 The original version of this class had a method:

   (CLLocationCoordinate2D)CLLocationCoordinate2DMakeWithWkt:(NSString *)wkt

 I removed it when I standardized the OTM API to always return a
 lat,lon dictionary, making the method obsolete. If you need to create a
 CLLocationCoordinate2D from WKT, look you can resurect this function from
 commit 4602ef34.

 */

/**
 Convert a dictionary containing point geometry attributes into a CLLocationCoordinate2D
 @param a dictionary containing values keyed with either 'lat' and 'lon' or 'x' and 'y'.
 @returns a CLLocationCoordinate2D representing the point specified in the dictionary.
 */
+ (CLLocationCoordinate2D)CLLocationCoordinate2DMakeWithDictionary:(NSDictionary *)dict;

@end
