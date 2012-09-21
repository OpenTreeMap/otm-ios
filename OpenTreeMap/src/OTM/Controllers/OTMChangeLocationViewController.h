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

#import <UIKit/UIKit.h>
#import "OTMTreeDetailViewController.h"
#import "OTMAddTreeAnnotationView.h"

@interface OTMChangeLocationViewController : UIViewController <MKMapViewDelegate, OTMAddTreeAnnotationViewDelegate> {
    MKPointAnnotation *treeAnnotation;
    MKMapView *mapView;
}

@property (nonatomic, strong) OTMTreeDetailViewController *delegate;
@property (nonatomic, strong) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) IBOutlet UISegmentedControl *mapModeSegmentedControl;

- (void)annotateCenter:(CLLocationCoordinate2D)center;

- (void)movedAnnotation:(MKPointAnnotation *)annotation;

@end
