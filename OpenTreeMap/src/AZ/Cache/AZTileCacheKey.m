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

-(NSString *)description {
    return [self cacheKey];
}

@end
