//
//  OTMChangeLocationViewController.h
//  OpenTreeMap
//
//  Created by Justin Walgran on 5/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OTMTreeDetailViewController.h"
#import "OTMAddTreeAnnotationView.h"

@interface OTMChangeLocationViewController : UIViewController <MKMapViewDelegate, OTMAddTreeAnnotationViewDelegate> {
    MKPointAnnotation *treeAnnotation;
    MKMapView *mapView;
}

@property (nonatomic, strong) OTMTreeDetailViewController *delegate;
@property (nonatomic, strong) IBOutlet MKMapView *mapView;

- (void)annotateCenter:(CLLocationCoordinate2D)center;

- (void)movedAnnotation:(MKPointAnnotation *)annotation;

@end
