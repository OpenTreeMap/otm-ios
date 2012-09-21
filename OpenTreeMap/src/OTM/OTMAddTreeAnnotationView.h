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

@protocol OTMAddTreeAnnotationViewDelegate <NSObject>
@required
- (void)movedAnnotation:(MKPointAnnotation *)annotation;
@end

@interface OTMAddTreeAnnotationView : MKAnnotationView {
    /**
     A flag to indicate whether this annotation is in the middle of being dragged
     */
    BOOL isMoving;

    /**
     The horizontal distance in pixels from the center of the annotation to the point
     at which the user touched and held the annotation. This annotation has a large
     'handle' so that it can be dragged without the center being obscured by the user's
     finger.
     */
    float touchXOffset;
    
    /**
     The vertical distance in pixels from the center of the annotation to the point
     at which the user touched and held the annotation. This annotation has a large
     'handle' so that it can be dragged without the center being obscured by the user's
     finger.
     */
    float touchYOffset;
}

/**
 A delegate that to receive events
 */
@property (nonatomic, strong) id <OTMAddTreeAnnotationViewDelegate> delegate;

/**
 A reference to the MKMapView to which this annotation has been added
 */
@property (nonatomic, strong) MKMapView *mapView;

@end
