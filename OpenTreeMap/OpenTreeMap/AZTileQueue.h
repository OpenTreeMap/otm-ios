//
//  AZTileQueue.h
//  OpenTreeMap
//
//  Created by Adam Hinz on 6/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTMAPI.h"
#import "OTMFilterListViewController.h"

@interface AZTileRequest : NSObject
@property (nonatomic,readonly) MKCoordinateRegion region;
@property (nonatomic,readonly) MKMapRect mapRect;
@property (nonatomic,readonly) MKZoomScale zoomScale;

@property (nonatomic,readonly,strong) OTMFilters *filters;
@property (nonatomic,readonly,copy) AZPointDataCallback callback;
@property (nonatomic,copy) Function1v operation;

-(id)initWithRegion:(MKCoordinateRegion)r mapRect:(MKMapRect)mr zoomScale:(MKZoomScale)zs
            filters:(OTMFilters *)f callback:(AZPointDataCallback)cb operation:(Function1v)op;

@end

@interface AZTileQueue : NSObject {
    NSMutableOrderedSet *queue;
}

@property (nonatomic,assign) MKMapRect visibleMapRect;
@property (nonatomic,assign) MKZoomScale zoomScale;
@property (nonatomic,strong) NSOperationQueue *opQueue;
@property (nonatomic,weak) OTMAPI *api;

-(void)queueRequest:(AZTileRequest *)req;
-(AZTileRequest *)dequeueRequest;

@end
