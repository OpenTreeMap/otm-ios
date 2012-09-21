//
//  AZPointCollection.h
//  OpenTreeMap
//
//  Created by Adam Hinz on 5/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AZPointCollection : NSObject

-(id)initWithMapRect:(MKMapRect)mRect zoomScale:(MKZoomScale)zScale points:(CFArrayRef)pts;

@property (nonatomic,readonly) MKMapRect mapRect;
@property (nonatomic,readonly) MKZoomScale zoomScale;
@property (nonatomic,readonly) CFArrayRef points;

@end
