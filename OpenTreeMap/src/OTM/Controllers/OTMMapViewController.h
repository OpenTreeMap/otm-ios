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
#import <CoreLocation/CoreLocation.h>
#import "OTMViewController.h"
#import "OTMAddTreeAnnotationView.h"
#import "OTMTreeDetailViewController.h"

#define kOTMMapViewControllerImageUpdate @"kOTMMapViewControllerImageUpdate"

typedef enum {
    Initial, // Initial should always be the first item in the enum
    Select,
    Add,
    Move,
} OTMMapViewControllerMapMode;

@interface OTMMapViewController : OTMViewController <MKMapViewDelegate, UIGestureRecognizerDelegate, UISearchBarDelegate, CLLocationManagerDelegate, OTMAddTreeAnnotationViewDelegate, OTMTreeDetailViewDelegate> {
    IBOutlet MKMapView *mapView;
    IBOutlet UISearchBar *searchBar;
    IBOutlet UIBarButtonItem *findLocationButton;
    BOOL firstAppearance;

    MKTileOverlay *plotsOverlay;
}

@property (nonatomic,strong) OTMFilters* filters;

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
@property (nonatomic,strong) IBOutlet UIView* addTreeHelpView;
@property (nonatomic,strong) IBOutlet UILabel* addTreeHelpLabel;
@property (nonatomic,strong) IBOutlet UINavigationBar* searchNavigationBar;
@property (nonatomic,strong) IBOutlet UIView* locationActivityView;
@property (nonatomic, strong) IBOutlet UISegmentedControl *mapModeSegmentedControl;
@property (nonatomic, strong) IBOutlet UIView *mapModeSegmentedControlBackground;
@property (nonatomic, strong) IBOutlet UIView *filterStatusView;
@property (nonatomic, strong) IBOutlet UILabel *filterStatusLabel;

@property (nonatomic,strong) NSDictionary* selectedPlot;

@property (nonatomic) OTMMapViewControllerMapMode mode;

@property (nonatomic,strong) MKPointAnnotation* addTreeAnnotation;
@property (nonatomic,copy) CLPlacemark *addTreePlacemark;

-(void)setDetailViewData:(NSDictionary*)plot;

-(IBAction) showTreePhotoFullscreen:(id)sender;
-(IBAction) startFindingLocation:(id)sender;
-(IBAction) stopFindingLocation:(id)sender;

@end
