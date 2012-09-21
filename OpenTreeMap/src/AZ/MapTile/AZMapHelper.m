//
// Copyright (c) 2012 Azavea
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//  

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
