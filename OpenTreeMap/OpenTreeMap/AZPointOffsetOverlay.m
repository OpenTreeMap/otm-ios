/*

 AZPointOffsetOverlay.m

 Created by Justin Walgran on 5/2/12.

 License
 =======
 Copyright (c) 2012 Azavea. All rights reserved.

 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

 */

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
