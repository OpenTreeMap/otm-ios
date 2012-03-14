//
//  OTMFirstViewController.h
//  OpenTreeMap
//
//  Created by Robert Cheetham on 2/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface OTMFirstViewController : UIViewController <MKMapViewDelegate, UIGestureRecognizerDelegate> {
    IBOutlet MKMapView *mapView;
}

@property (nonatomic,strong) MKPointAnnotation* lastClickedTree;
@property (nonatomic,assign) BOOL detailsVisible;

@property (nonatomic,strong) IBOutlet UIView* detailView;
@property (nonatomic,strong) IBOutlet UIImageView* treeImage;
@property (nonatomic,strong) IBOutlet UILabel* species;
@property (nonatomic,strong) IBOutlet UILabel* dbh;
@property (nonatomic,strong) IBOutlet UILabel* address;

@property (nonatomic,strong) NSDictionary* selectedPlot;
-(void)setDetailViewData:(NSDictionary*)plot;

@end
