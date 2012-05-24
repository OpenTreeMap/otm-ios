//
//  AZPointCollection.m
//  OpenTreeMap
//
//  Created by Adam Hinz on 5/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AZPointCollection.h"

@implementation AZPointCollection

@synthesize mapRect, zoomScale, points;

-(id)initWithMapRect:(MKMapRect)mRect zoomScale:(MKZoomScale)zScale points:(CFArrayRef)pts {
    if ((self = [super init])) {
        mapRect = mRect;
        zoomScale = zScale;
        points = pts;
        
        CFRetain(points);
    }
    
    return self;
}

-(void)dealloc {
    for(int i=0;i<CFArrayGetCount(points);i++) {
        free((void *)CFArrayGetValueAtIndex(points, i));
    }    
    
    CFRelease(points);
}

@end
