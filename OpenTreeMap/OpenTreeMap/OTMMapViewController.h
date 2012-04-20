//                                                                                                                
// Copyright (c) 2012 Azavea                                                                                
//                                                                                                                
// Permission is hereby granted, free of charge, to any person obtaining a copy                                   
// of this software and associated documentation files (the "Software"), to                                       
// deal in the Software without restriction, including without limitation the                                     
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or                                    
//  sell copies of the Software, and to permit persons to whom the Software is                                    
// furnished to do so, subject to the following conditions:                                                       
//                                                                                                                
// The above copyright notice and this permission notice shall be included in                                     
// all copies or substantial portions of the Software.                                                            
//                                                                                                                
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR                                     
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,                                       
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE                                    
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER                                         
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,                                  
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN                                      
// THE SOFTWARE.                                                                                                  
//  

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

#define kOTMMapViewControllerImageUpdate @"kOTMMapViewControllerImageUpdate"

@interface OTMMapViewController : UIViewController <MKMapViewDelegate, UIGestureRecognizerDelegate, UISearchBarDelegate, CLLocationManagerDelegate> {
    IBOutlet MKMapView *mapView;
    IBOutlet UISearchBar *searchBar;
    IBOutlet UIBarButtonItem *findLocationButton;
}

@property (nonatomic,strong) MKPointAnnotation* lastClickedTree;
@property (nonatomic,assign) BOOL detailsVisible;
@property (nonatomic,strong) CLLocationManager *locationManager;
@property (nonatomic,strong) CLLocation *mostAccurateLocationResponse;

@property (nonatomic,strong) IBOutlet MKMapView *mapView;
@property (nonatomic,strong) IBOutlet UIView* detailView;
@property (nonatomic,strong) IBOutlet UIImageView* treeImage;
@property (nonatomic,strong) IBOutlet UILabel* species;
@property (nonatomic,strong) IBOutlet UILabel* dbh;
@property (nonatomic,strong) IBOutlet UILabel* address;

@property (nonatomic,strong) NSDictionary* selectedPlot;

-(void)setDetailViewData:(NSDictionary*)plot;

-(IBAction) startFindingLocation:(id)sender;

@end
