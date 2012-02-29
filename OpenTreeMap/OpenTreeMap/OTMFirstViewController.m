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
#import "OTMAPI.h"

@interface OTMFirstViewController ()
- (void)setupMapView;

-(void)slideDetailUpAnimated:(BOOL)anim;
-(void)slideDetailDownAnimated:(BOOL)anim;
/**
 Append single-tap recognizer to the view that calls handleSingleTapGesture:
 */
- (void)addGestureRecognizersToView:(UIView *)view;
@end

@implementation OTMFirstViewController

@synthesize lastClickedTree, detailView, treeImage, dbh, species, address, detailsVisible;

- (void)viewDidLoad
{
    self.detailsVisible = NO;
    
    [super viewDidLoad];
    [self slideDetailDownAnimated:NO];
     
    [self setupMapView];
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

#pragma mark Detail View

-(void)setDetailViewData:(NSDictionary*)plot {
    NSString* tdbh = nil;
    NSString* tspecies = nil;
    NSString* taddress = nil;
    
    NSDictionary* tree;
    if ((tree = [plot objectForKey:@"tree"]) && [tree isKindOfClass:[NSDictionary class]]) {
        NSString* dbhValue = [tree objectForKey:@"dbh"];
        
        if (dbhValue != nil && ![[NSString stringWithFormat:@"%@", dbhValue] isEqualToString:@"<null>"]) {
            tdbh =  [NSString stringWithFormat:@"%@", dbhValue];   
        }
        
        tspecies = [NSString stringWithFormat:@"%@",[tree objectForKey:@"species_name"]];
    }
    
    taddress = [plot objectForKey:@"address"];
    
    if (tdbh == nil || tdbh == @"<null>") { tdbh = @"Diameter"; }
    if (tspecies == nil || tspecies == @"<null>") { tspecies = @"Species"; }
    if (taddress == nil || taddress == @"<null>") { taddress = @"Address"; }
    
    [self.dbh setText:tdbh];
    [self.species setText:tspecies];
    [self.address setText:taddress];
}

-(void)slideDetailUpAnimated:(BOOL)anim {
    if (anim) {
        [UIView beginAnimations:@"slidedetailup" context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        [UIView setAnimationDuration:0.2];
    }
    
    [self.detailView setFrame:
        CGRectMake(0,
                   self.view.bounds.size.height - self.detailView.frame.size.height,
                   self.view.bounds.size.width, 
                   self.detailView.frame.size.height)];
    
    self.detailsVisible = YES;
    
    if (anim) {
        [UIView commitAnimations];
    }
}

-(void)slideDetailDownAnimated:(BOOL)anim {
    if (anim) {
        [UIView beginAnimations:@"slidedetaildown" context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
        [UIView setAnimationDuration:0.2];
    }    
    
    [self.detailView setFrame:
     CGRectMake(0,
                self.view.bounds.size.height,
                self.view.bounds.size.width, 
                self.detailView.frame.size.height)];
    
    self.detailsVisible = NO;
    
    if (anim) {
        [UIView commitAnimations];
    }
}

#pragma mark Map view setup

- (void)setupMapView
{
    OTMEnvironment *env = [OTMEnvironment sharedEnvironment];

    MKCoordinateRegion region = [env mapViewInitialCoordinateRegion];
    [mapView setRegion:region animated:FALSE];
    [mapView regionThatFits:region];
    [mapView setDelegate:self];
    [self addGestureRecognizersToView:mapView];

    AZWMSOverlay *overlay = [[AZWMSOverlay alloc] init];

    [overlay setServiceUrl:[env geoServerWMSServiceURL]];
    [overlay setLayerNames:[env geoServerLayerNames]];
    [overlay setFormat:[env geoServerFormat]];

    [mapView addOverlay:overlay];
}

- (void)addGestureRecognizersToView:(UIView *)view
{
    UITapGestureRecognizer *singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTapGesture:)];
    singleTapRecognizer.numberOfTapsRequired = 1;
    singleTapRecognizer.numberOfTouchesRequired = 1;
    [view addGestureRecognizer:singleTapRecognizer];

    UITapGestureRecognizer *doubleTapRecognizer = [[UITapGestureRecognizer alloc] init];
    doubleTapRecognizer.numberOfTapsRequired = 2;
    doubleTapRecognizer.numberOfTouchesRequired = 1;

    // In order to pass double-taps to the underlying MKMapView the delegate for this recognizer (self) needs
    // to return YES from gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:
    doubleTapRecognizer.delegate = self;
    [view addGestureRecognizer:doubleTapRecognizer];

    // This prevents delays the single-tap recognizer slightly and ensures that it will _not_ fire if there is
    // a double-tap
    [singleTapRecognizer requireGestureRecognizerToFail:doubleTapRecognizer];
}

#pragma mark UIGestureRecognizer handlers

/**
 INCOMPLETE
 Get the latitude and longitude of the point on the map that was touched
 */
- (void)handleSingleTapGesture:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state != UIGestureRecognizerStateEnded)
    {
        return;
    }
    CGPoint touchPoint = [gestureRecognizer locationInView:mapView];
    CLLocationCoordinate2D touchMapCoordinate = [mapView convertPoint:touchPoint toCoordinateFromView:mapView];

    [[[OTMEnvironment sharedEnvironment] api] getPlotsNearLatitude:touchMapCoordinate.latitude
                                                         longitude:touchMapCoordinate.longitude
                                                          callback:^(NSArray* plots) 
    {
        if ([plots count] == 0) { // No plots returned
            [self slideDetailDownAnimated:YES];
        } else {            
            NSDictionary* plot = [plots objectAtIndex:0];
            NSDictionary* geom = [plot objectForKey:@"geometry"];
            
            NSDictionary* tree = [plot objectForKey:@"tree"];
            
            if (tree && [tree isKindOfClass:[NSDictionary class]]) {
                NSArray* images = [tree objectForKey:@"images"];
            
                if (images && [images isKindOfClass:[NSArray class]] && [images count] > 0) {
                    int imageId = [[[images objectAtIndex:0] objectForKey:@"id"] intValue];
                    int plotId = [[plot objectForKey:@"id"] intValue];
                    
                    [[[OTMEnvironment sharedEnvironment] api] getImageForTree:plotId
                                                                      photoId:imageId
                                                                     callback:^(UIImage* image)
                     {
                         self.treeImage.image = image;
                     }];
                }
            }
            
            [self setDetailViewData:plot];
            [self slideDetailUpAnimated:YES];
            
            double lat = [[geom objectForKey:@"lat"] doubleValue];
            double lon = [[geom objectForKey:@"lng"] doubleValue];
            CLLocationCoordinate2D center = CLLocationCoordinate2DMake(lat, lon);
            MKCoordinateSpan span = MKCoordinateSpanMake(0.003, 0.003);
            
            [mapView setRegion:MKCoordinateRegionMake(center, span) animated:YES];
            
            if (self.lastClickedTree) {
                [mapView removeAnnotation:self.lastClickedTree];
                self.lastClickedTree = nil;
            }
            
            self.lastClickedTree = [[MKPointAnnotation alloc] init];
            
            [self.lastClickedTree setCoordinate:center];
            
            [mapView addAnnotation:self.lastClickedTree];
            NSLog(@"Here with plot %@", plot); 
        }
    }];
    
    // TODO: Fetch nearest tree for lat lon
    NSLog(@"Touched lat:%f lon:%f",touchMapCoordinate.latitude, touchMapCoordinate.longitude);
}

#pragma mark UIGestureRecognizerDelegate methods

/**
 Asks the delegate if two gesture recognizers should be allowed to recognize gestures simultaneously.
 */
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    // Returning YES ensures that double-tap gestures propogate to the MKMapView
    return YES;
}

#pragma mark MKMapViewDelegate

- (void)mapView:(MKMapView*)mView regionDidChangeAnimated:(BOOL)animated {
    MKCoordinateRegion region = [mView region];
    double lngMin = region.center.longitude - region.span.longitudeDelta / 2.0;
    double lngMax = region.center.longitude + region.span.longitudeDelta / 2.0;
    double latMin = region.center.latitude - region.span.latitudeDelta / 2.0;
    double latMax = region.center.latitude + region.span.latitudeDelta / 2.0;
    
    if (self.lastClickedTree) {
        CLLocationCoordinate2D center = self.lastClickedTree.coordinate;
        
        BOOL shouldBeShown = center.longitude >= lngMin && center.longitude <= lngMax &&
                             center.latitude >= latMin && center.latitude <= latMax;

        if (shouldBeShown && !self.detailsVisible) {
            [self slideDetailUpAnimated:YES];
        } else if (!shouldBeShown && self.detailsVisible) {
            [self slideDetailDownAnimated:YES];
        }
    }
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay
{
    return [[AZWMSOverlayView alloc] initWithOverlay:overlay];
}

@end
