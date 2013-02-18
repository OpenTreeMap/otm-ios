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


#import "OTMImageViewController.h"
#import "AZWaitingOverlayController.h"

@interface OTMImageViewController ()

@end

@implementation OTMImageViewController 

- (void)loadImage:(NSString *)url {
    [[AZWaitingOverlayController sharedController] showOverlayWithTitle:@"Downloading"];
    [[[OTMEnvironment sharedEnvironment] api] getTreeImage:url callback:^(UIImage *image, NSError *error) {
        if (error) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                message:@"Could not download image"
                                                               delegate:nil
                                                        cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
            [alertView show];
        } else {
            self.imageView.image = image;
        }
        [[AZWaitingOverlayController sharedController] hideOverlay];
    }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
