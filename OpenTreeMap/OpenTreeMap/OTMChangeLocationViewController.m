//
//  OTMChangeLocationViewController.m
//  OpenTreeMap
//
//  Created by Justin Walgran on 5/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OTMChangeLocationViewController.h"

@implementation OTMChangeLocationViewController

@synthesize mapView, delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)annotateCenter:(CLLocationCoordinate2D)center
{
    if (!treeAnnotation) {
        treeAnnotation = [[MKPointAnnotation alloc] init];
    }
    
    [mapView removeAnnotation:treeAnnotation];
    
    // Set a small latitude delta to zoom the map in close to the point
    [mapView setRegion:MKCoordinateRegionMake(center, MKCoordinateSpanMake(0.001, 0.00)) animated:NO];
    
    treeAnnotation.coordinate = center;
    [mapView addAnnotation:treeAnnotation];
}

#define kOTMChangeLocationViewAnnotationViewReuseIdentifier @"kOTMChangeLocationViewAnnotationViewReuseIdentifier"

- (MKAnnotationView *)mapView:(MKMapView *)mv viewForAnnotation:(id <MKAnnotation>)annotation
{
    if (annotation == treeAnnotation) {
        MKAnnotationView *annotationView = [self.mapView dequeueReusableAnnotationViewWithIdentifier:kOTMChangeLocationViewAnnotationViewReuseIdentifier];
        if (!annotationView) {
            annotationView = [[OTMAddTreeAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:kOTMChangeLocationViewAnnotationViewReuseIdentifier];
            ((OTMAddTreeAnnotationView *)annotationView).delegate = self;
            ((OTMAddTreeAnnotationView *)annotationView).mapView = mv;
        }
        return annotationView;
    } else {
        return nil;
    }
}

- (void)movedAnnotation:(MKPointAnnotation *)annotation
{
    NSMutableDictionary *geometryDict = [delegate.data objectForKey:@"geometry"];
    
    [geometryDict setValue:[NSNumber numberWithFloat:annotation.coordinate.latitude] forKey:@"lat"];
    
    if ([geometryDict objectForKey:@"lon"]) {
        [geometryDict setValue:[NSNumber numberWithFloat:annotation.coordinate.longitude] forKey:@"lon"];
    } else {
        [geometryDict setValue:[NSNumber numberWithFloat:annotation.coordinate.longitude] forKey:@"lng"];
    }
    NSLog(@"Moved tree to %@", geometryDict);
    [delegate.tableView reloadData];
}

@end
