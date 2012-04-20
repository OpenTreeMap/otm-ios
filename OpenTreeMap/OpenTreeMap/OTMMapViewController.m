//                                                                                                                
// Copyright (c) 2012 Azavea                                                                                
//                                                                                                                
// Permission is hereby granted, free of charge, to any person obtaining a copy                                   
// of this software and associated documentation files (the "Software"), to                                       
// deal in the Software without restriction, including without limitation the                                     
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or                                    
//  sell copies of the Software, and to permit persons to whom the Software is                                    
// furnished to do so, subject to the following conditions:                                                       
//                                                                                                                
// The above copyright notice and this permission notice shall be included in                                     
// all copies or substantial portions of the Software.                                                            
//                                                                                                                
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR                                     
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,                                       
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE                                    
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER                                         
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,                                  
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN                                      
// THE SOFTWARE.                                                                                                  
//  

#import "OTMMapViewController.h"
#import "AZWMSOverlay.h"
#import "AZPointOffsetOverlay.h"
#import "OTMEnvironment.h"
#import "OTMAPI.h"
#import "OTMTreeDetailViewController.h"
#import "OTMAppDelegate.h"
#import "OTMDetailCellRenderer.h"

@interface OTMMapViewController ()
- (void)setupMapView;

-(void)slideDetailUpAnimated:(BOOL)anim;
-(void)slideDetailDownAnimated:(BOOL)anim;
/**
 Append single-tap recognizer to the view that calls handleSingleTapGesture:
 */
- (void)addGestureRecognizersToView:(UIView *)view;
@end

@implementation OTMMapViewController

@synthesize lastClickedTree, detailView, treeImage, dbh, species, address, detailsVisible, selectedPlot, locationManager, mostAccurateLocationResponse, mapView;

- (void)viewDidLoad
{
    self.detailsVisible = NO;
    
    self.title = [[OTMEnvironment sharedEnvironment] mapViewTitle];
    if (!self.title) {
        self.title = @"Tree Map";
    }

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updatedImage:)
                                                 name:kOTMMapViewControllerImageUpdate
                                               object:nil];    
    
    [super viewDidLoad];
    [self slideDetailDownAnimated:NO];
     
    [self setupMapView];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kOTMMapViewControllerImageUpdate
                                                  object:nil];
}

-(void)updatedImage:(NSNotification *)note {
    self.treeImage.image = note.object;
}

- (void)viewWillAppear:(BOOL)animated
{
    MKCoordinateRegion region = [(OTMAppDelegate *)[[UIApplication sharedApplication] delegate] mapRegion];
    [mapView setRegion:region];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender 
{
    if ([segue.identifier isEqualToString:@"Details"]) {
        OTMTreeDetailViewController *dest = segue.destinationViewController;
        [dest view]; // Force it load its view
        
        dest.data = self.selectedPlot;
        id keys = [NSArray arrayWithObjects:
                     [NSArray arrayWithObjects:                      
                      [NSDictionary dictionaryWithObjectsAndKeys:
                       @"id", @"key",
                       @"Tree Number", @"label", 
                       [NSNumber numberWithBool:YES], @"readonly",
                       nil],
                      [NSDictionary dictionaryWithObjectsAndKeys:
                       @"tree.sci_name", @"key",
                       @"Scientific Name", @"label",
                      [NSNumber numberWithBool:YES], @"readonly", nil],                      
                      [NSDictionary dictionaryWithObjectsAndKeys:
                       @"tree.dbh", @"key",
                       @"Trunk Diameter", @"label", 
                       @"fmtIn:", @"format",  
                       @"OTMDBHEditDetailCellRenderer", @"editClass",
                       nil],
                      [NSDictionary dictionaryWithObjectsAndKeys:
                       @"tree.height", @"key",
                       @"Tree Height", @"label",
                       @"fmtM:", @"format",  
                       nil],
                      [NSDictionary dictionaryWithObjectsAndKeys:
                       @"tree.canopy_height", @"key",
                       @"Canopy Height", @"label", 
                       @"fmtM:", @"format", 
                       nil],
                      nil],
                     nil];
        
        NSMutableArray *sections = [NSMutableArray array];
        for(NSArray *sectionArray in keys) {
            NSMutableArray *section = [NSMutableArray array];
            
            for(NSDictionary *rowDict in sectionArray) {
                [section addObject:
                 [OTMDetailCellRenderer cellRendererFromDict:rowDict]];
            }
            
            [sections addObject:section];
        }
        
        dest.keys = sections;
        dest.imageView.image = self.treeImage.image;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (IBAction)setMapMode:(UISegmentedControl *)sender {
    switch (sender.selectedSegmentIndex) {
        case 0:
            self.mapView.mapType = MKMapTypeStandard;
            break;
        case 1:
            self.mapView.mapType = MKMapTypeSatellite;
            break;
        default:
            self.mapView.mapType = MKMapTypeHybrid;
            break;
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

    // If the user taps the map while the searchBar is focused, dismiss the keyboard. This
    // mirrors the behavior of the iOS maps app.
    if ([searchBar isFirstResponder]) {
        [searchBar setShowsCancelButton:NO animated:YES];
        [searchBar resignFirstResponder];
        return;
    }

    CGPoint touchPoint = [gestureRecognizer locationInView:mapView];
    CLLocationCoordinate2D touchMapCoordinate = [mapView convertPoint:touchPoint toCoordinateFromView:mapView];

    [[[OTMEnvironment sharedEnvironment] api] getPlotsNearLatitude:touchMapCoordinate.latitude
                                                         longitude:touchMapCoordinate.longitude
                                                          callback:^(NSArray* plots, NSError* error) 
    {
        if ([plots count] == 0) { // No plots returned
            [self slideDetailDownAnimated:YES];
        } else {            
            NSDictionary* plot = [plots objectAtIndex:0];
            
            self.selectedPlot = [plot mutableDeepCopy];
            
            NSDictionary* geom = [plot objectForKey:@"geometry"];
            
            NSDictionary* tree = [plot objectForKey:@"tree"];
            
            self.treeImage.image = nil;
            
            if (tree && [tree isKindOfClass:[NSDictionary class]]) {
                NSArray* images = [tree objectForKey:@"images"];
                
                if (images && [images isKindOfClass:[NSArray class]] && [images count] > 0) {
                    int imageId = [[[images objectAtIndex:0] objectForKey:@"id"] intValue];
                    int plotId = [[plot objectForKey:@"id"] intValue];
                    
                    [[[OTMEnvironment sharedEnvironment] api] getImageForTree:plotId
                                                                      photoId:imageId
                                                                     callback:^(UIImage* image, NSError* error)
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
            MKCoordinateSpan span = [[OTMEnvironment sharedEnvironment] mapViewSearchZoomCoordinateSpan];
            
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

    [(OTMAppDelegate *)[[UIApplication sharedApplication] delegate] setMapRegion:region];

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
    return [[AZPointOffsetOverlay alloc] initWithOverlay:overlay];
}

#pragma mark UISearchBarDelegate methods

- (void)searchBarTextDidBeginEditing:(UISearchBar *)bar {
    [bar setShowsCancelButton:YES animated:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)bar {
    [bar setText:@""];
    [bar setShowsCancelButton:NO animated:YES];
    [searchBar resignFirstResponder];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)bar {
    NSString *searchText = [NSString stringWithFormat:@"%@ %@", [bar text], [[OTMEnvironment sharedEnvironment] searchSuffix]];
    [[[OTMEnvironment sharedEnvironment] api] geocodeAddress:searchText
        callback:^(NSArray* matches, NSError* error) {
            if ([matches count] > 0) {
                NSDictionary *firstMatch = [matches objectAtIndex:0];
                double lon = [[firstMatch objectForKey:@"x"] doubleValue];
                double lat = [[firstMatch objectForKey:@"y"] doubleValue];
                CLLocationCoordinate2D center = CLLocationCoordinate2DMake(lat, lon);
                MKCoordinateSpan span = [[OTMEnvironment sharedEnvironment] mapViewSearchZoomCoordinateSpan];
                [mapView setRegion:MKCoordinateRegionMake(center, span) animated:YES];
                [bar setShowsCancelButton:NO animated:YES];
                [bar resignFirstResponder];
            } else {
                NSString *message;
                if (error != nil) {
                    NSLog(@"Error geocoding location: %@", [error description]);
                    message = @"Sorry. There was a problem completing your search.";
                } else {
                    message = @"No Results Found";
                }
                [UIAlertView showAlertWithTitle:nil message:message cancelButtonTitle:@"OK" otherButtonTitle:nil callback:^(UIAlertView *alertView, int btnIdx) {
                    [bar setShowsCancelButton:YES animated:YES];
                    [bar becomeFirstResponder];
                }];
            }
       }];
}

#pragma mark CoreLocation handling

- (IBAction)startFindingLocation:(id)sender
{
    if ([CLLocationManager locationServicesEnabled]) {
        if (nil == [self locationManager]) {
            [self setLocationManager:[[CLLocationManager alloc] init]];
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        }
        // The delegate is cleared in stopFindingLocation so it must be reset here.
        [locationManager setDelegate:self];
        [locationManager startUpdatingLocation];
        NSTimeInterval timeout = [[[OTMEnvironment sharedEnvironment] locationSearchTimeoutInSeconds] doubleValue];
        [self performSelector:@selector(stopFindingLocationAndSetMostAccurateLocation) withObject:nil afterDelay:timeout];
    } else {
        [UIAlertView showAlertWithTitle:nil message:@"Location services are not available." cancelButtonTitle:@"OK" otherButtonTitle:nil callback:nil];
    }
}

- (void)stopFindingLocation {
    [[self locationManager] stopUpdatingLocation];
    // When using the debugger I found that extra events would arrive after calling stopUpdatingLocation.
    // Setting the delegate to nil ensures that those events are not ignored.
    [locationManager setDelegate:nil];
}

- (void)stopFindingLocationAndSetMostAccurateLocation {
    [self stopFindingLocation];
    if ([self mostAccurateLocationResponse] != nil) {
        MKCoordinateSpan span = [[OTMEnvironment sharedEnvironment] mapViewSearchZoomCoordinateSpan];
        [mapView setRegion:MKCoordinateRegionMake([[self mostAccurateLocationResponse] coordinate], span) animated:YES];
    }
    [self setMostAccurateLocationResponse:nil];
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    NSDate* eventDate = newLocation.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    // Avoid using any cached location results by making sure they are less than 15 seconds old
    if (abs(howRecent) < 15.0)
    {
        NSLog(@"Location accuracy: horizontal %f, vertical %f", [newLocation horizontalAccuracy], [newLocation verticalAccuracy]);

        if ([self mostAccurateLocationResponse] == nil || [[self mostAccurateLocationResponse] horizontalAccuracy] > [newLocation horizontalAccuracy]) {
            [self setMostAccurateLocationResponse: newLocation];
        }

        if ([newLocation horizontalAccuracy] > 0 && [newLocation horizontalAccuracy] < [manager desiredAccuracy]) {
            [self stopFindingLocation];
            [self setMostAccurateLocationResponse:nil];
            // Cancel the previous performSelector:withObject:afterDelay: - it's no longer necessary
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stopFindingLocation:) object:nil];

            NSLog(@"Found user's location: latitude %+.6f, longitude %+.6f\n",
                  newLocation.coordinate.latitude,
                  newLocation.coordinate.longitude);

            MKCoordinateSpan span = [[OTMEnvironment sharedEnvironment] mapViewSearchZoomCoordinateSpan];
            [mapView setRegion:MKCoordinateRegionMake(newLocation.coordinate, span) animated:YES];
        }
    }
}
@end
