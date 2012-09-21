/*
 
 OTMMapTableViewCell.h
 
 Created by Justin Walgran on 5/14/12.
 
 License
 =======
 Copyright (c) 2012 Azavea. All rights reserved.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 */

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
