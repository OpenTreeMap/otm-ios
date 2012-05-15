/*
 
 OTMMapTableViewCell.m
 
 Created by Justin Walgran on 5/14/12.
 
 License
 =======
 Copyright (c) 2012 Azavea. All rights reserved.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 */

#import "OTMMapTableViewCell.h"
#import <QuartzCore/QuartzCore.h>

@implementation OTMMapTableViewCell

@synthesize mapView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.mapView = [[MKMapView alloc] initWithFrame:CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, kOTMMapTableViewCellHeight)];

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

- (void)annotateCenter:(CLLocationCoordinate2D)center
{
    if (!annotation) {
        annotation = [[MKPointAnnotation alloc] init];
    }
    
    [mapView removeAnnotation:annotation];
    
    // Set a small latitude delta to zoom the map in close to the point
    [mapView setRegion:MKCoordinateRegionMake(center, MKCoordinateSpanMake(0.0007, 0.00)) animated:NO];
    
    annotation.coordinate = center;
    [mapView addAnnotation:annotation];
}

@end
