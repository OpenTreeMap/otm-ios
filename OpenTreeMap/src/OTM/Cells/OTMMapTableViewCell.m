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

#import "OTMMapTableViewCell.h"
#import <QuartzCore/QuartzCore.h>

@implementation OTMMapTableViewCell

@synthesize mapView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.mapView = [[MKMapView alloc] initWithFrame:CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, kOTMMapTableViewCellHeight)];
        self.mapView.delegate = self;

        self.mapView.layer.cornerRadius = 10.0;
        self.mapView.layer.borderWidth = 1.0;
        self.mapView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
        self.backgroundView = self.mapView;

        // The mini map in the table cell is never interactive since a small scrolling map view
        // will not work well nested inside a scrolling table view.
        [self.mapView setUserInteractionEnabled:NO];

        UIImage *detailImage = [UIImage imageNamed:@"detail"];
        detailImageView = [[UIImageView alloc] initWithImage:detailImage];

        detailImageView.frame = CGRectMake(
            self.mapView.frame.size.width - 40,
            (self.mapView.frame.size.height / 2) - (detailImage.size.height / 2),
            detailImage.size.width,
            detailImage.size.height
        );

        [detailImageView setHidden:YES];

        [self.backgroundView addSubview:detailImageView];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeMapMode:) name:kOTMChangeMapModeNotification object:nil];
    }
    return self;
}

- (void)setDetailArrowHidden:(BOOL)hidden
{
    detailImageView.hidden = hidden;
}

- (void)setHighlighted: (BOOL)highlighted animated: (BOOL)animated
{
    // don't highlight
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    // don't select
    //[super setSelected:selected animated:animated];
}

-(void)changeMapMode:(NSNotification *)note {
    self.mapView.mapType = (MKMapType)[note.object intValue];
}

- (void)annotateCenter:(CLLocationCoordinate2D)center
{
    self.mapView.mapType = (MKMapType)[SharedAppDelegate mapMode];

    if (!annotation) {
        annotation = [[MKPointAnnotation alloc] init];
    }
    
    [mapView removeAnnotation:annotation];
    
    // Set a small latitude delta to zoom the map in close to the point
    [mapView setRegion:MKCoordinateRegionMake(center, MKCoordinateSpanMake(0.0007, 0.00)) animated:NO];
    
    annotation.coordinate = center;
    [mapView addAnnotation:annotation];
}

#pragma mark MKMapViewDelegate Methods

#define kOTMMapTableViewCellSelectedTreeAnnotationViewReuseIdentifier @"kOTMMapTableViewCellSelectedTreeAnnotationViewReuseIdentifier"

- (MKAnnotationView *)mapView:(MKMapView *)mv viewForAnnotation:(id <MKAnnotation>)anno
{
    MKAnnotationView *annotationView = [self.mapView dequeueReusableAnnotationViewWithIdentifier:kOTMMapTableViewCellSelectedTreeAnnotationViewReuseIdentifier];

    if (!annotationView) {
        annotationView  = [[MKAnnotationView alloc]
            initWithAnnotation:anno
               reuseIdentifier:kOTMMapTableViewCellSelectedTreeAnnotationViewReuseIdentifier];
        annotationView.image = [UIImage imageNamed:@"selected_marker_small"];
        annotationView.centerOffset = CGPointMake(9,-19);
    }

    return annotationView;
}

@end
