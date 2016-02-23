// This file is part of the OpenTreeMap code.
//
// OpenTreeMap is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// OpenTreeMap is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with OpenTreeMap.  If not, see <http://www.gnu.org/licenses/>.

#import "OTMMapViewController.h"
#import "OTMFilterListViewController.h"
#import "OTMEnvironment.h"
#import "OTMAPI.h"
#import "OTMFormatter.h"
#import "OTMTreeDetailViewController.h"
#import "OTMAppDelegate.h"
#import "OTMDetailCellRenderer.h"
#import "OTMAddTreeAnnotationView.h"
#import "OTMTreeDictionaryHelper.h"
#import "OTMImageViewController.h"
#import "UIView+Borders.h"
#import "OTMTreeDictionaryHelper.h"
#import <QuartzCore/QuartzCore.h>

@interface OTMMapViewController ()
- (void)setupMapView;

- (void)disruptCoordinate:(CLLocationCoordinate2D)loc;

-(void)slideDetailUpAnimated:(BOOL)anim;
-(void)slideDetailDownAnimated:(BOOL)anim;
/**
 Append single-tap recognizer to the view that calls handleSingleTapGesture:
 */
- (void)addGestureRecognizersToView:(UIView *)view;

- (MKTileOverlay *)buildOverlayForLayer:(NSString *)layer
                                 filter:(NSString *)filter;
@end

@implementation OTMMapViewController

@synthesize lastClickedTree, detailView, treeImage, dbh, species, address, detailsVisible, selectedPlot, mode, locationManager, mapView, addTreeAnnotation, locationAnnotation, addTreeHelpView, addTreeHelpLabel, addTreePlacemark, locationActivityView, mapModeSegmentedControl, filters, filterStatusView, filterStatusLabel;

- (void)viewDidLoad
{
    [self setupView];
    [super viewDidLoad];
    [self updateViewWithSharedEnvironment];
}

// Handle all view setup that is not dependent on instance specific details
- (void)setupView {
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.extendedLayoutIncludesOpaqueBars = NO;
    self.automaticallyAdjustsScrollViewInsets = NO;

    self.mapView.showsPointsOfInterest = NO;

    firstAppearance = YES;

    self.detailsVisible = NO;

    [self changeMode:Select];

    [self.detailView addTopBorder];
    [self.addTreeHelpView addTopBorder];

    [self.filterStatusView addTopBorder];
    [self.filterStatusView addBottomBorder];

    // These 2 views are visible in the storyboard for design purposes, but
    // should start offscreen when the parent view first appears
    [self moveViewOffscreen:detailView];
    [self moveViewOffscreen:addTreeHelpView];

    [self hideFilterStatus];

    self.mapModeSegmentedControlBackground = [self addBackgroundViewBelowSegmentedControl:self.mapModeSegmentedControl];

    findLocationButton.opaque = NO;
    findLocationButton.layer.opacity = 0.95f;
    findLocationButton.frame = CGRectMake(261, mapView.frame.size.height - 17, findLocationButton.frame.size.width, findLocationButton.frame.size.height);
    findLocationButton.layer.masksToBounds = YES;
    findLocationButton.layer.cornerRadius = 5.0f;

    [self.tabBarController.tabBar setSelectedImageTintColor:[[OTMEnvironment sharedEnvironment] primaryColor]];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updatedImage:)
                                                 name:kOTMMapViewControllerImageUpdate
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(changeMapMode:)
                                                 name:kOTMChangeMapModeNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(changeEnvironment:)
                                                 name:kOTMEnvironmentChangeNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(changeGeoRev:)
                                                 name:kOTMGeoRevChangeNotification
                                               object:nil];

}

- (void)moveViewOffscreen:(UIView *)view {
    [view setFrame:
     CGRectMake(0,
                self.view.bounds.size.height,
                self.view.bounds.size.width,
                view.frame.size.height)];
}

// Update the view with instance specific details
- (void)updateViewWithSharedEnvironment {

    filters = [[OTMFilters alloc] init];
    filters.filters = [[OTMEnvironment sharedEnvironment] filters];

    // This sets the label at the top of the view, which can be different
    // from the tab bar item label
    self.navigationItem.title = [[OTMEnvironment sharedEnvironment] mapViewTitle];
    if (!self.navigationItem.title) {
        self.navigationItem.title = @"Tree Map";
    }

    [self setupMapView];
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kOTMMapViewControllerImageUpdate
                                                  object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                 name:kOTMChangeMapModeNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kOTMEnvironmentChangeNotification
                                                  object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kOTMGeoRevChangeNotification
                                                  object:nil];
}

-(void)updatedImage:(NSNotification *)note {
    self.treeImage.image = note.object;
}

- (void)viewWillAppear:(BOOL)animated
{
    if (firstAppearance) {
        firstAppearance = NO;
        NSLog(@"Trying to find location on first load of the map view");
        if ([CLLocationManager locationServicesEnabled]) {
            [self startFindingLocation:self];
        }
    }
}

/**
 This method is designed to mimic the response from the geo plot API so that the OTMTreeDetailViewController is always
 working with the same dictionary schema.
 */
- (NSMutableDictionary *)createAddTreeDictionaryFromAnnotation:(MKPointAnnotation *)annotation placemark:(CLPlacemark *)placemark
{
    NSMutableDictionary *geometryDict = [[NSMutableDictionary alloc] init];
    [geometryDict setObject:@"4326" forKey:@"srid"];
    [geometryDict setObject:[NSNumber numberWithDouble:annotation.coordinate.latitude] forKey:@"y"];
    [geometryDict setObject:[NSNumber numberWithDouble:annotation.coordinate.longitude] forKey:@"x"];
    [geometryDict setObject:[NSNumber numberWithInt:4326] forKey:@"srid"];

    NSMutableDictionary *addTreeDict = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *plotDict = [[NSMutableDictionary alloc] init];

    [addTreeDict setObject:plotDict forKey:@"plot"];
    [plotDict setObject:geometryDict forKey:@"geom"];

    if (addTreePlacemark) {
        [plotDict setObject:addTreePlacemark.name forKey:@"address_street"];
        if ([addTreePlacemark postalCode]) {
            [plotDict setObject:[addTreePlacemark postalCode] forKey:@"address_zip"];
        }
        if ([addTreePlacemark locality]) {
            [plotDict setObject:[addTreePlacemark locality] forKey:@"address_city"];
        }
    }

    // The edit view does not set values correctly if there isn't an empty tree property
    [addTreeDict setObject:[[NSMutableDictionary alloc] init] forKey:@"tree"];

    return addTreeDict;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Details"]) {
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Tree Map"style:UIBarButtonItemStyleBordered target:nil action:nil];

        OTMTreeDetailViewController *dest = segue.destinationViewController;
        [dest view]; // Force it to load its view
        dest.delegate = self;
        if (self.mode == Select) {
            dest.navigationItem.title = @"Tree Detail";
        } else if (self.mode == Add) {
            dest.navigationItem.title = @"New Tree";
        }


        if (self.mode == Select) {
            dest.data = self.selectedPlot;
        } else {
            dest.data = [self createAddTreeDictionaryFromAnnotation:self.addTreeAnnotation placemark:self.addTreePlacemark];
        }

        dest.originalLocation = [OTMTreeDictionaryHelper getCoordinateFromDictionary:dest.data];

        dest.originalData = [dest.data mutableDeepCopy];

        id keys = [[OTMEnvironment sharedEnvironment] fieldKeys];

        dest.keys = keys;
        dest.ecoKeys = [[OTMEnvironment sharedEnvironment] ecoFields];
        dest.imageView.image = self.treeImage.image;
        if (self.mode != Select) {
            // When adding a new tree the detail view is automatically in edit mode
            dest.startInEditMode = YES;
        }
    } else if ([segue.identifier isEqualToString:@"filtersList"]) {
        UINavigationController *nvc =segue.destinationViewController;
        OTMFilterListViewController *vc = (OTMFilterListViewController *)nvc.topViewController;
        [vc view]; // Force the view to load

        [vc setAllFilters:filters];

        vc.callback = ^(OTMFilters *f) {
            self.filters = f;
            [self showFilters:f];
        };
    } else if ([segue.identifier isEqualToString:@"showImage"]) {
        OTMImageViewController *controller = segue.destinationViewController;
        [controller loadImage:sender forPlot:self.selectedPlot];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:kOTMChangeMapModeNotification object:[NSNumber numberWithInt:sender.selectedSegmentIndex]];
}

- (IBAction)showTreePhotoFullscreen:(id)sender {
    NSString* photoURL = [OTMTreeDictionaryHelper getLatestPhotoUrlInDictionary:self.selectedPlot];
    if (photoURL) {
        [self performSegueWithIdentifier:@"showImage" sender:photoURL];
    }
}

-(void)changeMapMode:(NSNotification *)note {
    mapModeSegmentedControl.selectedSegmentIndex = [note.object intValue];
    self.mapView.mapType = (MKMapType)[note.object intValue];
}

-(void)changeEnvironment:(NSNotification *)note {
    OTMEnvironment *env = note.object;
    [self.tabBarController.tabBar setSelectedImageTintColor:[env primaryColor]];
    [self.filterStatusView setBackgroundColor:env.secondaryColor];
}

-(void)changeGeoRev:(NSNotification *)note {
    [self showFilters:self.filters];
}

#pragma mark Detail View

-(void)setDetailViewData:(NSDictionary*)plot {
    NSString* tdbh = nil;
    NSString* tspecies = nil;
    NSString* taddress = [self buildAddressStringFromPlotDictionary:plot];

    NSDictionary* tree;
    if ((tree = [plot objectForKey:@"tree"]) && [tree isKindOfClass:[NSDictionary class]]) {
        NSDictionary *pendingEdits = [plot objectForKey:@"pending_edits"];

        NSDictionary *latestSpeciesEdit = [[[pendingEdits objectForKey:@"tree.species"] objectForKey:@"pending_edits"] objectAtIndex:0];
        if (latestSpeciesEdit) {
            tspecies = [[latestSpeciesEdit objectForKey:@"related_fields"] objectForKey:@"tree.species_name"];
        } else {
            NSDictionary *speciesDict = [tree objectForKey:@"species"];
            if (![speciesDict isKindOfClass:[NSNull class]]) {
                tspecies = [speciesDict objectForKey:@"common_name"];
            }
        }
    }

    if (tdbh == nil || [tdbh isEqual:@"<null>"]) { tdbh = @"Missing Diameter"; }
    if (tspecies == nil || [tspecies isEqual:@"<null>"]) { tspecies = @"Missing Species"; }

    [self.species setText:tspecies];
    [self.address setText:[taddress uppercaseString]];
}


-(void)slideUpBottomDockedView:(UIView *)view animated:(BOOL)anim {
    if (anim) {
        [UIView beginAnimations:[NSString stringWithFormat:@"slideup%@", view] context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        [UIView setAnimationDuration:0.2];
    }

    bool viewIsChangingYPosition = view.frame.origin.y != self.view.bounds.size.height - view.frame.size.height;
    if (viewIsChangingYPosition) {
        CGRect bf = findLocationButton.frame;
        [findLocationButton setFrame:CGRectMake(bf.origin.x,
                                                bf.origin.y - view.frame.size.height,
                                                bf.size.width,
                                                bf.size.height)];
    }

    [view setFrame:
     CGRectMake(0,
                self.view.bounds.size.height - view.frame.size.height,
                self.view.bounds.size.width,
                view.frame.size.height)];

    if (anim) {
        [UIView commitAnimations];
    }
}

-(void)slideDetailUpAnimated:(BOOL)anim {
    [self slideUpBottomDockedView:self.detailView animated:anim];
    self.detailsVisible = YES;
}

-(void)slideAddTreeHelpUpAnimated:(BOOL)anim {
    [self slideUpBottomDockedView:self.addTreeHelpView animated:anim];
}

-(void)slideDownBottomDockedView:(UIView *)view animated:(BOOL)anim {
    if (anim) {
        [UIView beginAnimations:[NSString stringWithFormat:@"slidedown%@", view] context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
        [UIView setAnimationDuration:0.2];
    }

    bool viewIsChangingYPosition = view.frame.origin.y != self.view.bounds.size.height + view.frame.size.height;
    if (viewIsChangingYPosition) {
        CGRect bf = findLocationButton.frame;
        [findLocationButton setFrame:CGRectMake(bf.origin.x,
                                                bf.origin.y + view.frame.size.height,
                                                bf.size.width,
                                                bf.size.height)];
    }

    [view setFrame:
     CGRectMake(0,
                self.view.bounds.size.height,
                self.view.bounds.size.width,
                view.frame.size.height)];

    if (anim) {
        [UIView commitAnimations];
    }
}

-(void)slideDetailDownAnimated:(BOOL)anim {
    if (detailsVisible) {
        [self slideDownBottomDockedView:self.detailView animated:anim];
        self.detailsVisible = NO;
    }
}

-(void)slideAddTreeHelpDownAnimated:(BOOL)anim {
    [self slideDownBottomDockedView:self.addTreeHelpView animated:anim];
}

#pragma mark Map view setup

- (MKTileOverlay *)buildOverlayForLayer:(NSString *)layer
                                 filter:(NSString *)filter {
    OTMEnvironment *env = [OTMEnvironment sharedEnvironment];
    NSString *iid = [env instanceId];
    NSString *grev = [env geoRev];

    NSString *urlSfx = [env.api2 tileUrlTemplateForInstanceId:iid
                                                       geoRev:grev
                                                        layer:layer];

    if (filter != nil) {
        filter = [OTMAPI urlEncode:filter];
        urlSfx = [urlSfx stringByAppendingFormat:@"&q=%@", filter];
    }

    if ([[OTMEnvironment sharedEnvironment] tileQueryStringAdditionalArguments]) {
        urlSfx = [NSString stringWithFormat:@"%@&%@", urlSfx,
                  [[OTMEnvironment sharedEnvironment] tileQueryStringAdditionalArguments]];
    }

    NSString *host = env.tilerUrl;
    NSString *url = [host stringByAppendingString:urlSfx];

    return [[MKTileOverlay alloc] initWithURLTemplate:url];
}

- (void)setupMapView
{
    OTMEnvironment *env = [OTMEnvironment sharedEnvironment];

    MKCoordinateRegion region = [env mapViewInitialCoordinateRegion];
    [SharedAppDelegate setMapRegion:region];

    [mapView setRegion:region animated:NO];
    [mapView regionThatFits:region];
    [mapView setDelegate:self];
    [self addGestureRecognizersToView:mapView];

    MKTileOverlay *boundsOverlay =
        [self buildOverlayForLayer:@"treemap_boundary"
                            filter:nil];

    [mapView addOverlay:boundsOverlay];

    // Add the plot layer, showing all plots
    [self setMapFilter:nil];

}

- (void)setMapFilter:(NSString *)filter {
    if (plotsOverlay != nil) {
        [mapView removeOverlay:plotsOverlay];
    }

    plotsOverlay =
      [self buildOverlayForLayer:@"treemap_mapfeature"
                          filter:filter];

    [mapView addOverlay:plotsOverlay];
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

#pragma mark mode management methods

- (void)clearSelectedTree
{
    if (self.lastClickedTree) {
        [self.mapView removeAnnotation:self.lastClickedTree];
        self.lastClickedTree = nil;
    }
    if (self.detailsVisible) {
        [self slideDetailDownAnimated:YES];
    }
}

- (void)changeMode:(OTMMapViewControllerMapMode)newMode
{
    if (newMode == self.mode) {
        return;
    }

    if (newMode == Add) {
        self.navigationItem.title = @"Add A Tree";
        self.navigationItem.leftBarButtonItem.title = @"Cancel";
        self.navigationItem.leftBarButtonItem.target = self;
        self.navigationItem.leftBarButtonItem.action = @selector(cancelAddTree);
        self.navigationItem.rightBarButtonItem = nil;

        [self clearSelectedTree];
        self.addTreeHelpLabel.text = @"Step 1: Tap the new tree location";
        [self slideAddTreeHelpUpAnimated:YES];

    } else if (newMode == Move) {
        self.navigationItem.leftBarButtonItem.title = @"Cancel";
        self.navigationItem.leftBarButtonItem.target = self;
        self.navigationItem.leftBarButtonItem.action = @selector(cancelMoveNewTree);
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStyleBordered target:self action:@selector(showNewTreeEditView)];
        [self crossfadeLabel:self.addTreeHelpLabel newText:@"Step 2: Move tree into position then click Next"];

    } else if (newMode == Select) {
        if (self.addTreeAnnotation) {
            [self.mapView removeAnnotation:self.addTreeAnnotation];
            self.addTreeAnnotation = nil;
        }
        self.navigationItem.title = [[OTMEnvironment sharedEnvironment] mapViewTitle];
        self.navigationItem.leftBarButtonItem.title = @"Filter";
        self.navigationItem.leftBarButtonItem.target = self;
        self.navigationItem.leftBarButtonItem.action = @selector(showFilters);
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStyleBordered target:self action:@selector(startAddingTree)];
        [self slideAddTreeHelpDownAnimated:YES];
    }

    self.mode = newMode;
}

- (void)showFilters {
    [self performSegueWithIdentifier:@"filtersList" sender:self];
}

- (void)crossfadeLabel:(UILabel *)label newText:(NSString *)newText
{
    [UIView beginAnimations:[NSString stringWithFormat:@"crossfadelabel%@", label] context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    [UIView setAnimationDuration:0.6];

    label.alpha = 0;
    label.text = newText;
    label.alpha = 1;

    [UIView commitAnimations];
}

- (void)slidePointAnnotation:(MKPointAnnotation *)annotation toCoordinate:(CLLocationCoordinate2D)coordinate
{
    [UIView beginAnimations:[NSString stringWithFormat:@"slideannotation%@", annotation] context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    [UIView setAnimationDuration:0.2];

    annotation.coordinate = coordinate;

    [UIView commitAnimations];
}

- (void)cancelAddTree
{
    [self changeMode:Select];
}

- (void)cancelMoveNewTree
{
    [self changeMode:Select];
}

- (void)showFilters:(OTMFilters *)f
{
    if ([f active]) {
        [self showFilterStatusWithMessage:[NSString stringWithFormat:@"Filter: %@", [f description]]];
    } else {
        [self hideFilterStatus];
    }

    NSString *filter = [f filtersAsUrlParameter];

    [self setMapFilter:filter];
    // TODO: hide the wizard label
}

- (void)startAddingTree
{
    OTMLoginManager* loginManager = [SharedAppDelegate loginManager];

    [loginManager presentModelLoginInViewController:self.parentViewController callback:^(BOOL success, OTMUser *aUser) {
        if (success) {
            loginManager.loggedInUser = aUser;
            [self changeMode:Add];
        }
    }];
}

- (void)showNewTreeEditView
{
    [self performSegueWithIdentifier:@"Details" sender:self];
}

#pragma mark tap response methods

- (void)selectTreeNearCoordinate:(CLLocationCoordinate2D)coordinate
{
    OTMLoginManager* loginManager = [SharedAppDelegate loginManager];

    [[[OTMEnvironment sharedEnvironment] api] getPlotsNearLatitude:coordinate.latitude
                   longitude:coordinate.longitude
                        user:loginManager.loggedInUser
                    callback:^(NSArray* plots, NSError* error)
     {
         if ([plots count] == 0) { // No plots returned
             [self clearSelectedTree];
         } else {
             NSDictionary* plot = [plots objectAtIndex:0];
             [self selectPlot:plot];
             NSLog(@"Here with plot %@", plot);
         }
     }];
}

- (void)selectPlot:(NSDictionary *)dict
{
    [self selectPlot:dict andShowPhoto:nil];
}

- (void)selectPlot:(NSDictionary *)dict andShowPhoto:(UIImage *)photo
{
    self.selectedPlot = [dict mutableDeepCopy];

    NSDictionary *plot = [dict objectForKey:@"plot"];

    if (photo) {
        self.treeImage.image = photo;
    } else {
        self.treeImage.image = [UIImage imageNamed:@"Default_feature-image"];
        NSString *photoUrl = [OTMTreeDictionaryHelper getLatestPhotoUrlInDictionary:dict];
        if (photoUrl) {
            dispatch_async(dispatch_get_global_queue(0,0), ^{
                NSData *imageData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:photoUrl]];

                dispatch_async(dispatch_get_main_queue(), ^{
                    self.treeImage.image = [UIImage imageWithData: imageData];
                });
            });
        }
    }

    [self setDetailViewData:dict];
    [self slideDetailUpAnimated:YES];

    CLLocationCoordinate2D center = [OTMTreeDictionaryHelper getCoordinateFromDictionary:plot];

    [self zoomMapIfNeededAndCenterMapOnCoordinate:center];

    if (self.lastClickedTree) {
        [mapView removeAnnotation:self.lastClickedTree];
        self.lastClickedTree = nil;
    }

    self.lastClickedTree = [[MKPointAnnotation alloc] init];

    [self.lastClickedTree setCoordinate:center];

    [mapView addAnnotation:self.lastClickedTree];
}

- (void)zoomMapIfNeededAndCenterMapOnCoordinate:(CLLocationCoordinate2D)coordinate
{
    MKCoordinateSpan defaultZoomSpan = [[OTMEnvironment sharedEnvironment] mapViewSearchZoomCoordinateSpan];

    if (defaultZoomSpan.latitudeDelta < mapView.region.span.latitudeDelta
        || defaultZoomSpan.longitudeDelta < mapView.region.span.longitudeDelta) {
        [mapView setRegion:MKCoordinateRegionMake(coordinate, defaultZoomSpan) animated:YES];
    } else {
        [mapView setCenterCoordinate:coordinate animated:YES];
    }
}

- (void)fetchAndSetAddTreePlacemarkForCoordinate:(CLLocationCoordinate2D)coordinate
{
    [[[OTMEnvironment sharedEnvironment] api] reverseGeocodeCoordinate:coordinate callback:^(NSArray *placemarks, NSError *error) {
        if (placemarks && [placemarks count] > 0) {
            self.addTreePlacemark = [placemarks objectAtIndex:0];
            NSLog(@"Set add tree placemark to %@", self.addTreePlacemark);
        };
    }];
}

- (void)placeNewTreeAnnotation:(CLLocationCoordinate2D)coordinate
{
    if (!self.addTreeAnnotation) {
        self.addTreeAnnotation = [[MKPointAnnotation alloc] init];
        self.addTreeAnnotation.coordinate = coordinate;
        [self.mapView addAnnotation:self.addTreeAnnotation];
    } else {
        [self slidePointAnnotation:self.addTreeAnnotation toCoordinate:coordinate];
    }
    [self fetchAndSetAddTreePlacemarkForCoordinate:coordinate];
    [self changeMode:Move];
}

- (void)placeLocationAnnotation:(CLLocationCoordinate2D)coordinate
{
    if (!self.locationAnnotation) {
        self.locationAnnotation = [[MKPointAnnotation alloc] init];
        self.locationAnnotation.coordinate = coordinate;
        [self.mapView addAnnotation:self.locationAnnotation];
    } else {
        [self slidePointAnnotation:self.locationAnnotation toCoordinate:coordinate];
    }
}

#pragma mark UIGestureRecognizer handlers

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

    if (!mode || mode == Select) {
        [self selectTreeNearCoordinate:touchMapCoordinate];

    } else if (mode == Add) {
        [self placeNewTreeAnnotation:touchMapCoordinate];
        [self changeMode:Move];

    } else if (mode == Move) {
        [self placeNewTreeAnnotation:touchMapCoordinate];
    }

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

    [SharedAppDelegate setMapRegion:region];

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

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id < MKOverlay >)overlay {
    return [[MKTileOverlayRenderer alloc] initWithTileOverlay:overlay];
}

#define kOTMMapViewAddTreeAnnotationViewReuseIdentifier @"kOTMMapViewAddTreeAnnotationViewReuseIdentifier"
#define kOTMMapViewLocationAnnotationViewReuseIdentifier @"kOTMMapViewLocationAnnotationViewReuseIdentifier"

#define kOTMMapViewSelectedTreeAnnotationViewReuseIdentifier @"kOTMMapViewSelectedTreeAnnotationViewReuseIdentifier"

- (MKAnnotationView *)mapView:(MKMapView *)mv viewForAnnotation:(id <MKAnnotation>)annotation
{
    MKAnnotationView *annotationView;
    if (annotation == self.locationAnnotation) {
        annotationView = [self.mapView dequeueReusableAnnotationViewWithIdentifier:kOTMMapViewLocationAnnotationViewReuseIdentifier];
        if (!annotationView) {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation
                                                          reuseIdentifier:kOTMMapViewLocationAnnotationViewReuseIdentifier];
            annotationView.image = [UIImage imageNamed:@"location_marker"];
        }
    } else if (annotation == self.addTreeAnnotation) {
        annotationView = [self.mapView dequeueReusableAnnotationViewWithIdentifier:kOTMMapViewAddTreeAnnotationViewReuseIdentifier];
        if (!annotationView) {
            annotationView = [[OTMAddTreeAnnotationView alloc] initWithAnnotation:annotation
                                                                  reuseIdentifier:kOTMMapViewAddTreeAnnotationViewReuseIdentifier];
            ((OTMAddTreeAnnotationView *)annotationView).delegate = self;
            ((OTMAddTreeAnnotationView *)annotationView).mapView = mv;
        }
    } else { // The only three annotation types on the map are location, add tree, and selected tree
        annotationView = [self.mapView dequeueReusableAnnotationViewWithIdentifier:kOTMMapViewSelectedTreeAnnotationViewReuseIdentifier];
        if (!annotationView) {
            annotationView = [[MKAnnotationView alloc]
                initWithAnnotation:annotation
                   reuseIdentifier:kOTMMapViewSelectedTreeAnnotationViewReuseIdentifier];
            annotationView.image = [UIImage imageNamed:@"selected_marker"];
            annotationView.centerOffset = CGPointMake(12,-29);
        }
    }
    return annotationView;
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
                [mapView setRegion:MKCoordinateRegionMake(center, span) animated:NO];
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

#pragma mark Location handling

- (IBAction)startFindingLocation:(id)sender
{
    if (!locationActivityView) {
        locationActivityView = [[UIActivityIndicatorView alloc]
                                initWithActivityIndicatorStyle:
                                UIActivityIndicatorViewStyleWhite];

        [(UIActivityIndicatorView *)locationActivityView startAnimating];
        [locationActivityView setUserInteractionEnabled:NO];

        CGSize bs = findLocationButton.frame.size;
        CGSize as = locationActivityView.frame.size;
        CGFloat offsetx = (bs.width - as.width) / 2;
        CGFloat offsety = (bs.height - as.height) / 2;
        [locationActivityView setFrame:CGRectMake(offsetx, offsety, locationActivityView.frame.size.width, locationActivityView.frame.size.height)];
    }
    [findLocationButton addSubview:locationActivityView];
    [findLocationButton setImage:nil forState:UIControlStateNormal];
    [findLocationButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    [findLocationButton addTarget:self action:@selector(stopFindingLocation:) forControlEvents:UIControlEventTouchUpInside];

    if (!locationManager) {
        locationManager = [[OTMLocationManager alloc] init];
    }

    [locationManager findLocation:^(CLLocation *location, NSError *error) {
        if (!error) {
            [self stopFindingLocation:self]; // Handles updating the UI now that the location has been found
            MKCoordinateSpan span = [[OTMEnvironment sharedEnvironment] mapViewSearchZoomCoordinateSpan];
            [mapView setRegion:MKCoordinateRegionMake(location.coordinate, span) animated:NO];
            [self placeLocationAnnotation:location.coordinate];
        } else {
            NSLog(@"Failed to get location");
        }
    }];
}

- (IBAction)stopFindingLocation:(id)sender {
    [findLocationButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    [findLocationButton addTarget:self action:@selector(startFindingLocation:) forControlEvents:UIControlEventTouchUpInside];
    if (locationManager) {
        [locationManager stopFindingLocation];
    }
    [findLocationButton setImage:[UIImage imageNamed:@"gps_icon"] forState:UIControlStateNormal];
    [locationActivityView removeFromSuperview];
}

#pragma mark OTMAddTreeAnnotationView delegate methods

- (void)movedAnnotation:(MKPointAnnotation *)annotation
{
    [self fetchAndSetAddTreePlacemarkForCoordinate:annotation.coordinate];
}

#pragma mark OTMTreeDetailViewDelegate methods

- (void)disruptCoordinate:(CLLocationCoordinate2D)coordinate {
}

- (void)viewController:(OTMTreeDetailViewController *)viewController addedTree:(NSDictionary *)details withPhoto:(UIImage *)photo
{
    [self changeMode:Select];
    CLLocationCoordinate2D coordinate = [OTMTreeDictionaryHelper getCoordinateFromDictionary:details];

    [self disruptCoordinate:coordinate];

    [self selectPlot:details andShowPhoto:photo];
    [self.navigationController popViewControllerAnimated:YES];
}


- (void)viewController:(OTMTreeDetailViewController *)viewController editedTree:(NSDictionary *)details withOriginalLocation:(CLLocationCoordinate2D)coordinate originalData:(NSDictionary *)originalData
{
    [self viewController:viewController editedTree:details withOriginalLocation:coordinate originalData:originalData withPhoto:nil];
}

- (void)viewController:(OTMTreeDetailViewController *)viewController editedTree:(NSDictionary *)details withOriginalLocation:(CLLocationCoordinate2D)coordinate originalData:(NSDictionary *)originalData withPhoto:(UIImage *)photo
{
    CLLocationCoordinate2D newCoordinate = [OTMTreeDictionaryHelper getCoordinateFromDictionary:details];

    [self disruptCoordinate:coordinate];
    [self disruptCoordinate:newCoordinate];

    [self selectPlot:details andShowPhoto:photo];

    self.selectedPlot = [details mutableDeepCopy];
    [self setDetailViewData:details];
}

- (void)plotDeletedByViewController:(OTMTreeDetailViewController *)viewController
{
    CLLocationCoordinate2D coordinate = [OTMTreeDictionaryHelper getCoordinateFromDictionary:selectedPlot];

    [self disruptCoordinate:coordinate];

    [self clearSelectedTree];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)treeAddCanceledByViewController:(OTMTreeDetailViewController *)viewController
{
    [self changeMode:Select];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark Filter Status

- (void)hideFilterStatus
{
    [self.filterStatusView setHidden:YES];
    [self.mapModeSegmentedControl setFrame:CGRectMake(8, 55, 185, 30)];
    [self updateBackgroundView:self.mapModeSegmentedControlBackground forSegmentedControl:self.mapModeSegmentedControl];
}

- (void)showFilterStatusWithMessage:(NSString *)message
{
    [self.filterStatusLabel setText:message];
    [self.mapModeSegmentedControl setFrame:CGRectMake(8, 79, 185, 30)];
    [self updateBackgroundView:self.mapModeSegmentedControlBackground forSegmentedControl:self.mapModeSegmentedControl];
    [self.filterStatusView setHidden:NO];
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
