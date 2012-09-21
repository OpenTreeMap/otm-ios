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

#import "AZPointOffsetOverlay.h"

@implementation AZPointOffsetOverlay

@synthesize boundingMapRect; // from <MKOverlay>
@synthesize coordinate;      // from <MKOverlay>
@synthesize overlayId;

-(id) init {
    self = [super init];
    if (!self) { return nil; }

    /*
     A comment from https://github.com/mtigas/iOS-MapLayerDemo

     "The Google Mercator projection is slightly off from the "standard" Mercator projection, used by MapKit. My understanding is that this is due to Google Maps' use of a Spherical Mercator projection, where the poles are cut off -- the effective map ending at approx. +/- 85º. MapKit does not(?), therefore, our origin point (top-left) must be moved accordingly."
     */
    boundingMapRect = MKMapRectWorld;
    boundingMapRect.origin.x += 1048600.0;
    boundingMapRect.origin.y += 1048600.0;

    coordinate = CLLocationCoordinate2DMake(0, 0);

    return self;
}

@end
