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

#import "OTMChangeLocationViewController.h"
#import "OTMTreeDictionaryHelper.h"

@implementation OTMChangeLocationViewController

@synthesize mapView, delegate, mapModeSegmentedControl;

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

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeMapMode:) name:kOTMChangeMapModeNotification object:nil];

    self.mapModeSegmentedControl.selectedSegmentIndex = [SharedAppDelegate mapMode];

    self.mapView.mapType = (MKMapType)[SharedAppDelegate mapMode];
}

- (IBAction)setMapMode:(UISegmentedControl *)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:kOTMChangeMapModeNotification object:[NSNumber numberWithInt:sender.selectedSegmentIndex]];
}

-(void)changeMapMode:(NSNotification *)note {
    self.mapView.mapType = (MKMapType)[note.object intValue];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    NSMutableDictionary *data = [delegate.data mutableDeepCopy];
    [OTMTreeDictionaryHelper setCoordinate:annotation.coordinate inDictionary:data];
    delegate.data = data;
    [delegate.tableView reloadData];
}

@end
