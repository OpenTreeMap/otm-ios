/*
 
 OTMAddTreeViewController.m
 
 Created by Justin Walgran on 4/9/12.
 
 License
 =======
 Copyright (c) 2012 Azavea. All rights reserved.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
 documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
 rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit
 persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
 Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
 WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
 OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 */

#import "OTMAddTreeViewController.h"
#import "OTMAppDelegate.h"
#import "AZWMSOverlay.h"
#import "AZPointOffsetOverlay.h"

@interface OTMAddTreeViewController ()

@end

@implementation OTMAddTreeViewController

@synthesize activeTreeAnnotation, messageLabel, addDetailButton, addAnotherButton, cleanMapButton;

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
	self.title = @"Add Tree";
    
    [self setupMapView];
    [self addGestureRecognizersToView:mv];
    
    [[self addDetailButton] setHidden:YES];
    [[self addAnotherButton] setHidden:YES];
    [[self cleanMapButton] setHidden:YES];
    
    MKCoordinateRegion region = [(OTMAppDelegate *)[[UIApplication sharedApplication] delegate] mapRegion];
    [mv setRegion:region];
    
    [super viewDidLoad];
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

- (void)viewWillAppear:(BOOL)animated
{
    MKCoordinateRegion region = [(OTMAppDelegate *)[[UIApplication sharedApplication] delegate] mapRegion];
   [mv setRegion:region];
}

- (void)setupMapView 
{
    OTMEnvironment *env = [OTMEnvironment sharedEnvironment];
    
    MKCoordinateRegion region = [env mapViewInitialCoordinateRegion];
    [mv setRegion:region animated:FALSE];
    [mv regionThatFits:region];   
    [mv setDelegate:self];
    
    AZWMSOverlay *overlay = [[AZWMSOverlay alloc] init];    
    [mv addOverlay:overlay];
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay
{
    return [[AZPointOffsetOverlay alloc] initWithOverlay:overlay];
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

/**
 Asks the delegate if two gesture recognizers should be allowed to recognize gestures simultaneously.
 */
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    // Returning YES ensures that double-tap gestures propogate to the MKMapView
    return YES;
}

- (void)handleSingleTapGesture:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state != UIGestureRecognizerStateEnded)
    {
        return;
    }
    
    CGPoint touchPoint = [gestureRecognizer locationInView:mv];
    CLLocationCoordinate2D touchMapCoordinate = [mv convertPoint:touchPoint toCoordinateFromView:mv];
    
    if ([self activeTreeAnnotation]) {
        [mv removeAnnotation:[self activeTreeAnnotation]];
    }
    
    [self setActiveTreeAnnotation:[[MKPointAnnotation alloc] init]];
    
    [[self activeTreeAnnotation] setCoordinate:touchMapCoordinate];
    
    [mv addAnnotation:[self activeTreeAnnotation]];

    [[self messageLabel] setHidden:YES];
    [[self cleanMapButton] setHidden:NO];
    [[self addDetailButton] setHidden:NO];
    [[self addAnotherButton] setHidden:NO];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    MKAnnotationView *treeAnnotationView;

    if (annotation == activeTreeAnnotation) {
        treeAnnotationView = (MKPinAnnotationView *) [mapView dequeueReusableAnnotationViewWithIdentifier:@"ActiveTree"];
        if (treeAnnotationView == nil) {
            treeAnnotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"ActiveTree"];
        } else {
            treeAnnotationView.annotation = annotation;
        }

        [(MKPinAnnotationView *)treeAnnotationView setAnimatesDrop:YES];
        [treeAnnotationView setDraggable:YES];
    } else {
        treeAnnotationView = (MKAnnotationView *) [mapView dequeueReusableAnnotationViewWithIdentifier:@"AddedTree"];
        if (treeAnnotationView == nil) {
            treeAnnotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"AddedTree"];
            [treeAnnotationView setImage:[UIImage imageNamed:@"marker-selected-sm"]];
        } else {
            treeAnnotationView.annotation = annotation;
        }
    }

    return treeAnnotationView;
}

- (void)mapView:(MKMapView*)mView regionDidChangeAnimated:(BOOL)animated 
{
    MKCoordinateRegion region = [mView region];
    
    [(OTMAppDelegate *)[[UIApplication sharedApplication] delegate] setMapRegion:region];
}

- (void)changeActiveAnnotationToNewTreeAnnotation
{
    // Removing and adding back the annotation after setting the active annotation
    // to nil ensures that it is drawn with a different icon.
    id annotation = [self activeTreeAnnotation];
    [mv removeAnnotation:annotation];
    [self setActiveTreeAnnotation:nil];
    [mv addAnnotation:annotation];
}

- (IBAction)addAnother:(id)sender
{
    // TODO: Add a plot to the database / update tile
    
    [self changeActiveAnnotationToNewTreeAnnotation];
    
    [[self messageLabel] setHidden:NO];
    [[self cleanMapButton] setHidden:YES];
    [[self addDetailButton] setHidden:YES];
    [[self addAnotherButton] setHidden:YES];
}

- (IBAction)addDetail:(id)sender
{
    // TODO: Show detail editor

    [UIAlertView showAlertWithTitle:nil message:@"This is where the detail editor will slide in" cancelButtonTitle:@"OK" otherButtonTitle:nil callback:nil];

    [self changeActiveAnnotationToNewTreeAnnotation];

    [[self messageLabel] setHidden:NO];
    [[self cleanMapButton] setHidden:YES];
    [[self addDetailButton] setHidden:YES];
    [[self addAnotherButton] setHidden:YES];
}

- (IBAction)cleanMap:(id)sender
{
    if ([self activeTreeAnnotation]) {
        [mv removeAnnotation:[self activeTreeAnnotation]];
    }    
    
    [[self messageLabel] setHidden:NO];
    [[self cleanMapButton] setHidden:YES];
    [[self addDetailButton] setHidden:YES];
    [[self addAnotherButton] setHidden:YES];
}

@end
