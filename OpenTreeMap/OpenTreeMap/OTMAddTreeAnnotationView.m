//
//  OTMAddTreeAnnotationView.m
//  OpenTreeMap
//
//  Created by Justin Walgran on 4/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OTMAddTreeAnnotationView.h"

@implementation OTMAddTreeAnnotationView

@synthesize mapView;

- (id)initWithAnnotation:(id <MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier {
	self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    
	if (self) {
		self.image = [UIImage imageNamed:@"handle_icon"];
	}
	return self;
}

-(void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
    isMoving = YES;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event 
{
    if (isMoving) {
        UITouch *touch = [[event allTouches] anyObject];
        CGPoint point = [touch locationInView:self.superview];
        CLLocationCoordinate2D newCoordinate = [mapView convertPoint:point 
                                            toCoordinateFromView:self.superview]; 
        self.annotation.coordinate = newCoordinate;
    } else {
        [super touchesMoved:touches withEvent:event];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    isMoving = NO;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    isMoving = NO;
}

@end
