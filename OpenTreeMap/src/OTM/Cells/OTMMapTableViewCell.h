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
#import <MapKit/MapKit.h>

#define kOTMMapTableViewCellHeight 120

/*
 A table cell for displaying a "mini map" on the tree details page
 */
@interface OTMMapTableViewCell : UITableViewCell <MKMapViewDelegate> {
    MKPointAnnotation *annotation;
    UIImageView *detailImageView;
}

/*
 The map view used to render the "mini map"
 */
@property (nonatomic,strong) IBOutlet MKMapView *mapView;

/*
 Add an MKPointAnnotation to the map and zoom and center the
 map on the specified point.
 */
- (void)annotateCenter:(CLLocationCoordinate2D)center;

/*
 Show or hide the detail arrow indicating that a subview can
 be accessed by clicking the cell
 */
- (void)setDetailArrowHidden:(BOOL)hidden;

@end
