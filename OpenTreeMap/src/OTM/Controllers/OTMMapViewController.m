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

@synthesize lastClickedTree, detailView, treeImage, dbh, species, address, detailsVisible, selectedPlot, mode, locationManager, mostAccurateLocationResponse, mapView, addTreeAnnotation, addTreeHelpView, addTreeHelpLabel, addTreePlacemark, searchNavigationBar, locationActivityView, mapModeSegmentedControl, filters, filterStatusView, filterStatusLabel;

- (void)viewDidLoad
{
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.extendedLayoutIncludesOpaqueBars = NO;
    self.automaticallyAdjustsScrollViewInsets = NO;

    OTMLoginManager* loginManager = [SharedAppDelegate loginManager];
    AZUser* user = [loginManager loggedInUser];

    OTM2API *api = [[OTMEnvironment sharedEnvironment] api2];
    NSString *instance = [[OTMEnvironment sharedEnvironment] instance];
    [api loadInstanceInfo:instance
                  forUser:user
             withCallback:^(id json, NSError *error) {
            if (error) {
                if ([[[error userInfo] objectForKey:@"statusCode"] intValue] == 401) {
                    [loginManager presentModelLoginInViewController:self.parentViewController callback:^(BOOL success, OTMUser *aUser) {
                            if (success) {
                                loginManager.loggedInUser = aUser;
                                [self changeMode:Add];
                            }
                        }];
                }
            } else {
                [[OTMEnvironment sharedEnvironment] updateEnvironmentWithDictionary:json];
                [self initView];
            }
      }];
}

- (void)initView {
    firstAppearance = YES;

    self.detailsVisible = NO;

    [self changeMode:Select];

    filters = [[OTMFilters alloc] init];
    filters.filters = [[OTMEnvironment sharedEnvironment] filters];

    // This sets the label at the top of the view, which can be different
    // from the tab bar item label
    self.navigationItem.title = [[OTMEnvironment sharedEnvironment] mapViewTitle];
    if (!self.navigationItem.title) {
        self.navigationItem.title = @"Tree Map";
    }

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updatedImage:)
                                                 name:kOTMMapViewControllerImageUpdate
                                               object:nil];


    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(changeMapMode:)
                                                 name:kOTMChangeMapModeNotification
                                               object:nil];

    [super viewDidLoad];
    [self slideDetailDownAnimated:NO];
    [self slideAddTreeHelpDownAnimated:NO];

    [self hideFilterStatus];

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
}

-(void)updatedImage:(NSNotification *)note {
    self.treeImage.image = note.object;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.tabBarController.tabBar setSelectedImageTintColor:[[OTMEnvironment sharedEnvironment] navBarTintColor]];

    self.addTreeHelpLabel.textColor = [UIColor whiteColor];
    self.addTreeHelpLabel.shadowColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    self.addTreeHelpLabel.shadowOffset = CGSizeMake(0, -1);

    MKCoordinateRegion region = [SharedAppDelegate mapRegion];
    [mapView setRegion:region];
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
    [geometryDict setObject:[NSNumber numberWithFloat:annotation.coordinate.latitude] forKey:@"y"];
    [geometryDict setObject:[NSNumber numberWithFloat:annotation.coordinate.longitude] forKey:@"x"];
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
        [dest view]; // Force it load its view
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
            [dest startOrCommitEditing:self];
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
        [controller loadImage:sender];
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
    NSArray *images = [[self.selectedPlot objectForKey:@"tree"] objectForKey:@"images"];
    NSString* imageURL = [[images objectAtIndex:0] objectForKey:@"url"];

    if (imageURL) {
        [self performSegueWithIdentifier:@"showImage" sender:imageURL];
    }
}

-(void)changeMapMode:(NSNotification *)note {
    mapModeSegmentedControl.selectedSegmentIndex = [note.object intValue];
    self.mapView.mapType = (MKMapType)[note.object intValue];
}

#pragma mark Detail View

-(void)setDetailViewData:(NSDictionary*)plot {
    NSString* tdbh = nil;
    NSString* tspecies = nil;
    NSString* taddress = nil;

    NSDictionary* tree;
    if ((tree = [plot objectForKey:@"tree"]) && [tree isKindOfClass:[NSDictionary class]]) {
        NSDictionary *pendingEdits = [plot objectForKey:@"pending_edits"];
        NSDictionary *latestDbhEdit = [[[pendingEdits objectForKey:@"tree.diameter"] objectForKey:@"pending_edits"] objectAtIndex:0];

        NSString* dbhValue;

        if (latestDbhEdit) {
            dbhValue = [latestDbhEdit objectForKey:@"value"];
        } else {
            dbhValue = [tree objectForKey:@"diameter"];
        }

        OTMFormatter *fmt = [[OTMEnvironment sharedEnvironment] dbhFormat];

        if (dbhValue != nil && ![[NSString stringWithFormat:@"%@", dbhValue] isEqualToString:@"<null>"]) {
            tdbh =  [fmt format:[dbhValue floatValue]];
        }

        NSDictionary *latestSpeciesEdit = [[[pendingEdits objectForKey:@"tree.species"] objectForKey:@"pending_edits"] objectAtIndex:0];
        if (latestSpeciesEdit) {
            tspecies = [[latestSpeciesEdit objectForKey:@"related_fields"] objectForKey:@"tree.species_name"];
        } else {
            NSDictionary *speciesDict = [tree objectForKey:@"species"];
            if (![speciesDict isKindOfClass:[NSNull class]]) {
                tspecies = [speciesDict objectForKey:@"scientific_name"];
            }
        }
    }

    taddress = [plot objectForKey:@"address"];

    if (tdbh == nil || [tdbh isEqual:@"<null>"]) { tdbh = @"Missing Diameter"; }
    if (tspecies == nil || [tspecies isEqual:@"<null>"]) { tspecies = @"Missing Species"; }
    if (taddress == nil || [taddress isEqual:@"<null>"] ||
            [taddress isKindOfClass:[NSNull class]] ||
            [taddress isEqualToString:@""]) { taddress = @"No Address"; }

    [self.dbh setText:tdbh];
    [self.species setText:tspecies];
    [self.address setText:taddress];
}


-(void)slideUpBottomDockedView:(UIView *)view animated:(BOOL)anim {
    if (anim) {
        [UIView beginAnimations:[NSString stringWithFormat:@"slideup%@", view] context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        [UIView setAnimationDuration:0.2];
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
    [self slideDownBottomDockedView:self.detailView animated:anim];
    self.detailsVisible = NO;
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

    NSString *host = env.host;
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

- (void)slideAddTreeAnnotationToCoordinate:(CLLocationCoordinate2D)coordinate
{
    [UIView beginAnimations:[NSString stringWithFormat:@"slideannotation%@", self.addTreeAnnotation] context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    [UIView setAnimationDuration:0.2];

    self.addTreeAnnotation.coordinate = coordinate;

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

    OTMAPI *api = [[OTMEnvironment sharedEnvironment] api];
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
                     filters:self.filters
                    callback:^(NSArray* plots, NSError* error)
     {
         if ([plots count] == 0) { // No plots returned
             [self slideDetailDownAnimated:YES];
         } else {
             NSDictionary* plot = [plots objectAtIndex:0];
             [self selectPlot:plot];
             NSLog(@"Here with plot %@", plot);
         }
     }];
}

- (void)selectPlot:(NSDictionary *)dict
{
    self.selectedPlot = [dict mutableDeepCopy];

    NSDictionary *plot = [dict objectForKey:@"plot"];
    NSDictionary* tree = [dict objectForKey:@"tree"];

    self.treeImage.image = nil;

    if (tree && [tree isKindOfClass:[NSDictionary class]]) {
        NSArray* images = [dict objectForKey:@"photos"];

        if (images && [images isKindOfClass:[NSArray class]] && [images count] > 0) {
            NSString *photoUrl = [[images lastObject] objectForKey:@"image"];

            if (![photoUrl hasPrefix:@"http"]) {
                NSString *baseUrl = [[OTMEnvironment sharedEnvironment] baseURL];
                NSURL *url = [NSURL URLWithString:baseUrl];
                NSString *host = [url host];
                NSString *scheme = [url scheme];
                NSString *port = [url port];
                photoUrl = [NSString stringWithFormat:@"%@://%@:%@%@", scheme, host, port, photoUrl];
            }

            dispatch_async(dispatch_get_global_queue(0,0), ^{
                    NSData * imageData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:photoUrl]];

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
        [self slideAddTreeAnnotationToCoordinate:coordinate];
    }
    [self fetchAndSetAddTreePlacemarkForCoordinate:coordinate];
    [self changeMode:Move];
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

#define kOTMMapViewSelectedTreeAnnotationViewReuseIdentifier @"kOTMMapViewSelectedTreeAnnotationViewReuseIdentifier"

- (MKAnnotationView *)mapView:(MKMapView *)mv viewForAnnotation:(id <MKAnnotation>)annotation
{
    MKAnnotationView *annotationView;
    if (annotation == self.addTreeAnnotation) {
        annotationView = [self.mapView dequeueReusableAnnotationViewWithIdentifier:kOTMMapViewAddTreeAnnotationViewReuseIdentifier];
        if (!annotationView) {
            annotationView = [[OTMAddTreeAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:kOTMMapViewAddTreeAnnotationViewReuseIdentifier];
            ((OTMAddTreeAnnotationView *)annotationView).delegate = self;
            ((OTMAddTreeAnnotationView *)annotationView).mapView = mv;
        }
    } else { // The only two annotation types on the map are add tree and selected tree
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

#pragma mark CoreLocation handling

- (IBAction)startFindingLocation:(id)sender
{
    if ([CLLocationManager locationServicesEnabled]) {

        if (!locationActivityView) {
            locationActivityView = [[UIActivityIndicatorView alloc]
                                    initWithActivityIndicatorStyle:
                                    UIActivityIndicatorViewStyleWhite];

            [(UIActivityIndicatorView *)locationActivityView startAnimating];
            [locationActivityView setUserInteractionEnabled:NO];
            [locationActivityView setFrame:CGRectMake(12, 12, locationActivityView.frame.size.width, locationActivityView.frame.size.height)];
        }

        [searchNavigationBar addSubview:locationActivityView];
        findLocationButton.image = [UIImage imageNamed:@"transparent_14"];
        findLocationButton.action = @selector(stopFindingLocation:);

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

- (IBAction)stopFindingLocation:(id)sender {
    findLocationButton.action = @selector(startFindingLocation:);
    [[self locationManager] stopUpdatingLocation];
    // When using the debugger I found that extra events would arrive after calling stopUpdatingLocation.
    // Setting the delegate to nil ensures that those events are not ignored.
    [locationManager setDelegate:nil];
    findLocationButton.image = [UIImage imageNamed:@"gps_icon_14"];
    [locationActivityView removeFromSuperview];
}


- (void)stopFindingLocationAndSetMostAccurateLocation {
    [self stopFindingLocation:self];
    if ([self mostAccurateLocationResponse] != nil) {
        MKCoordinateSpan span = [[OTMEnvironment sharedEnvironment] mapViewSearchZoomCoordinateSpan];
        CLLocation *loc = [self mostAccurateLocationResponse];
        CLLocationCoordinate2D coord = [loc coordinate];

        OTMEnvironment *env = [OTMEnvironment sharedEnvironment];
        CLLocationCoordinate2D center = env.mapViewInitialCoordinateRegion.center;
        CLLocationDistance dist = [loc distanceFromLocation:[[CLLocation alloc] initWithLatitude:center.latitude longitude:center.longitude]];

        if (dist < [env searchRegionRadiusInMeters]) {
            [mapView setRegion:MKCoordinateRegionMake(coord, span) animated:NO];
        }
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
            [self stopFindingLocation:self];
            [self setMostAccurateLocationResponse:nil];
            // Cancel the previous performSelector:withObject:afterDelay: - it's no longer necessary
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stopFindingLocation:) object:nil];

            NSLog(@"Found user's location: latitude %+.6f, longitude %+.6f\n",
                  newLocation.coordinate.latitude,
                  newLocation.coordinate.longitude);

            OTMEnvironment *env = [OTMEnvironment sharedEnvironment];
            MKCoordinateSpan span = [env mapViewSearchZoomCoordinateSpan];
            CLLocationCoordinate2D center = env.mapViewInitialCoordinateRegion.center;

            CLLocationDistance dist = [newLocation distanceFromLocation:[[CLLocation alloc] initWithLatitude:center.latitude longitude:center.longitude]];

            if (dist < [env searchRegionRadiusInMeters]) {
                [mapView setRegion:MKCoordinateRegionMake(newLocation.coordinate, span) animated:NO];
            }
        }
    }
}

#pragma mark OTMAddTreeAnnotationView delegate methods

- (void)movedAnnotation:(MKPointAnnotation *)annotation
{
    [self fetchAndSetAddTreePlacemarkForCoordinate:annotation.coordinate];
}

#pragma mark OTMTreeDetailViewDelegate methods

- (void)disruptCoordinate:(CLLocationCoordinate2D)coordinate {
}

- (void)viewController:(OTMTreeDetailViewController *)viewController addedTree:(NSDictionary *)details
{
    [self changeMode:Select];
    CLLocationCoordinate2D coordinate = [OTMTreeDictionaryHelper getCoordinateFromDictionary:details];

    [self disruptCoordinate:coordinate];

    [self selectPlot:details];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewController:(OTMTreeDetailViewController *)viewController editedTree:(NSDictionary *)details withOriginalLocation:(CLLocationCoordinate2D)coordinate originalData:(NSDictionary *)originalData
{
    CLLocationCoordinate2D newCoordinate = [OTMTreeDictionaryHelper getCoordinateFromDictionary:details];

    [self disruptCoordinate:coordinate];
    [self disruptCoordinate:newCoordinate];

    [self selectPlot:details];

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
    [self.mapModeSegmentedControl setFrame:CGRectMake(130, 50, 185, 30)];
}

- (void)showFilterStatusWithMessage:(NSString *)message
{
    [self.filterStatusLabel setText:message];
    [self.mapModeSegmentedControl setFrame:CGRectMake(130, 74, 185, 30)];
    [self.filterStatusView setHidden:NO];
}

@end
