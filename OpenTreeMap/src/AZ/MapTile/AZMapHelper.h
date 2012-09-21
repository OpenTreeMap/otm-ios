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
