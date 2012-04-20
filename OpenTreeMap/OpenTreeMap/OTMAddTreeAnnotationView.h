//
//  OTMAddTreeAnnotationView.h
//  OpenTreeMap
//
//  Created by Justin Walgran on 4/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface OTMAddTreeAnnotationView : MKAnnotationView {
    BOOL isMoving;
}
    
@property (nonatomic, strong) MKMapView *mapView;

@end
