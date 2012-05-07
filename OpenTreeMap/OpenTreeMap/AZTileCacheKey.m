/*
 
 AZTileCacheKey.m

 Created by Justin Walgran on 5/3/12.

 License
 =======
 Copyright (c) 2012 Azavea. All rights reserved.

 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

 */

#import "AZTileCacheKey.h"

@implementation AZTileCacheKey (Private)

- (NSString *)cacheKey
{
    return [NSString stringWithFormat:@"%f,%f,%f,%f,%f", mapRect.origin.x, mapRect.origin.y, mapRect.size.width, mapRect.size.width, zoomScale];
}

@end

@implementation AZTileCacheKey

@synthesize mapRect, zoomScale;

+ (AZTileCacheKey *)keyWithMapRect:(MKMapRect)rect zoomScale:(MKZoomScale)scale 
{
    return [[AZTileCacheKey alloc] initWithMapRect:rect zoomScale:scale];
}

- (id)initWithMapRect:(MKMapRect)rect zoomScale:(MKZoomScale)scale
{
    self = [super init];
    if (self) {
        mapRect = rect;
        zoomScale = scale;
    }
    return self;
}

#pragma mark NSCopying protocol

- (id)copyWithZone:(NSZone *)zone 
{
    return [[AZTileCacheKey allocWithZone:zone] initWithMapRect:self.mapRect zoomScale:self.zoomScale];
}

#pragma mark NSObject methods

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    
    if (!other)
        return NO;
    
    if (![other isKindOfClass:[AZTileCacheKey class]])
        return NO;
    
    return [[self cacheKey] isEqualToString:[other cacheKey]];
}

- (NSUInteger)hash
{
    return [[self cacheKey] hash];
}

@end
