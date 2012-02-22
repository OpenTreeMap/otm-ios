//
//  OTMFirstViewController.m
//  OpenTreeMap
//
//  Created by Robert Cheetham on 2/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OTMFirstViewController.h"
#import "AZWMSOverlay.h"
#import "AZWMSOverlayView.h"
#import "OTMEnvironment.h"

@interface OTMFirstViewController ()
- (void)createAndAddMapView;
@end

@implementation OTMFirstViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self createAndAddMapView];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

#pragma mark Map view setup

- (void)createAndAddMapView
{
    OTMEnvironment *env = [OTMEnvironment sharedEnvironment];

    MKMapView *mapView = [[MKMapView alloc] initWithFrame:self.view.bounds];
    MKCoordinateRegion region = [env mapViewInitialCoordinateRegion];
    [mapView setRegion:region animated:FALSE];
    [mapView regionThatFits:region];
    [mapView setDelegate:self];

    AZWMSOverlay *overlay = [[AZWMSOverlay alloc] init];

    [overlay setServiceUrl:[env geoServerWMSServiceURL]];
    [overlay setLayerNames:[env geoServerLayerNames]];

    [mapView addOverlay:overlay];

    [self.view addSubview:mapView];
}

#pragma mark MKMapViewDelegate

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay
{
    return [[AZWMSOverlayView alloc] initWithOverlay:overlay];
}

@end
