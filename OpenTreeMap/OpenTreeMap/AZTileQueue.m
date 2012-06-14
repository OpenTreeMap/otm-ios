//
//  AZTileQueue.m
//  OpenTreeMap
//
//  Created by Adam Hinz on 6/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AZTileQueue.h"

@implementation AZTileRequest
@synthesize region, mapRect, zoomScale, filters, callback, operation;

-(id)initWithRegion:(MKCoordinateRegion)r mapRect:(MKMapRect)mr zoomScale:(MKZoomScale)zs
            filters:(OTMFilters *)f callback:(AZPointDataCallback)cb operation:(Function1v)op {
    if ((self = [super init])) {
        region = r;
        mapRect = mr;
        zoomScale = zs;
        filters = f;
        callback = cb;
        operation = op;
    }

    return self;
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    
    if (!other)
        return NO;
    
    if (![other isKindOfClass:[AZTileRequest class]])
        return NO;
    
    return [[self description] isEqualToString:[other description]];
}

- (NSUInteger)hash
{
    return [[self description] hash];
}

-(NSString *)description {
    return [NSString stringWithFormat:@"%@,%f",MKStringFromMapRect(mapRect),zoomScale];
}


@end


@implementation AZTileQueue

@synthesize visibleMapRect, zoomScale, opQueue, api;

-(id)init {
    if ((self = [super init])) {
        queue = [[NSMutableOrderedSet alloc] init];
    }

    return self;
}

-(void)setVisibleMapRect:(MKMapRect)r zoomScale:(MKZoomScale)z {
    @synchronized(self) {
        visibleMapRect = r;
        zoomScale = z;
        [self sort];
    }
}        

-(void)setVisibleMapRect:(MKMapRect)r {
    @synchronized(self) {
        visibleMapRect = r;
        [self sort];
    }
}

-(void)setZoomScale:(MKZoomScale)z {
    @synchronized(self) {
        zoomScale = z;
        [self sort];
    }
}

-(void)queueRequest:(AZTileRequest *)req {
    @synchronized(self) {
        [queue addObject:req];
        [self sort];

        NSLog(@"Enqueue: Queue contains %d objects",[queue count]);
        [self pushOpQueue];
    }
}

-(void)pushOpQueue {
    [opQueue addOperation:[NSBlockOperation blockOperationWithBlock:^{
                AZTileRequest *r = [self dequeueRequest];
                NSLog(@"Dequeue: Queue contains %d objects",[queue count]);
                if (r && r.operation) {
                    r.operation(r);
                }
            }]];
}

-(NSComparisonResult)distanceOrdering:(AZTileRequest *)a to:(AZTileRequest *)b {
    double dist2a = [self distanceTo:a.mapRect];
    double dist2b = [self distanceTo:b.mapRect];
    if (dist2a < dist2b) { // A is closer
        return NSOrderedDescending; // B is before A
    } else if (dist2a > dist2b) {
        return NSOrderedAscending; // A is before B
    } else { // equal
        return NSOrderedSame;
    }
}

-(void)sort {
    NSLog(@"Enqueue: Sorting %d objects",[queue count]);
    [queue sortUsingComparator:^(AZTileRequest *a, AZTileRequest *b) {
            // Use zoom level first
            if (a.zoomScale != b.zoomScale) {
                // Pick the zoom level closest to our current one
                int zoomDiffA = ABS(a.zoomScale - zoomScale);
                int zoomDiffB = ABS(b.zoomScale - zoomScale);
                if (zoomDiffA < zoomDiffB) { // A is closer
                    return (NSComparisonResult)NSOrderedDescending; // B is before A
                } else if (zoomDiffA > zoomDiffB) { // B is closer
                    return (NSComparisonResult)NSOrderedAscending; // A is before B in the array
                } else { // Equal zoom values, queue in order of distance
                    return (NSComparisonResult)[self distanceOrdering:a to:b];
                }
            } else { // zoom scale is the same
                return (NSComparisonResult)[self distanceOrdering:a to:b];
            }
        }];
}

// returns distance^2 from the center of the visible rect to the center of
// r
-(double)distanceTo:(MKMapRect)r {
    double cx = r.origin.x + r.size.width/2.0;
    double cy = r.origin.y + r.size.height/2.0;

    double vx = visibleMapRect.origin.x + visibleMapRect.size.width/2.0;
    double vy = visibleMapRect.origin.y + visibleMapRect.size.height/2.0;

    return (cx - vx)*(cx - vx) + (cy-vy)*(cy-vy);
}

-(AZTileRequest *)dequeueRequest {
    @synchronized(self) {
        if ([queue count] > 0) {
            AZTileRequest *r = [queue lastObject];
            [queue removeObjectAtIndex:[queue count] - 1];
            return r;
        } else {
            return nil;
        }
    }
}

@end
