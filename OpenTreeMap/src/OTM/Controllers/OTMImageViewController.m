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
#import "OTMTreeDictionaryHelper.h"
#import "OTMInappropriateContentMailViewController.h"

@interface OTMImageViewController ()

@end

@implementation OTMImageViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.screenName = @"Image";  // for Google Analytics
    }
    return self;
}

- (void)loadImage:(NSString *)url forPlot:(NSDictionary *)plot
{
    self.data = plot;
    self.imageView.image = nil;
    [[AZWaitingOverlayController sharedController] showOverlayWithTitle:@"Downloading"];

    dispatch_async(dispatch_get_global_queue(0,0), ^{
        NSData *imageData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:url]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[AZWaitingOverlayController sharedController] hideOverlay];
            if (imageData) {
                UIImage *image = [UIImage imageWithData: imageData];
                self.imageView.image = image;
                self.scrollView.contentSize = self.imageView.image.size;
                self.imageView.frame = CGRectMake(0, 0, self.imageView.image.size.width, self.imageView.image.size.height);
                self.scrollView.minimumZoomScale = self.scrollView.frame.size.width / image.size.width;
                self.scrollView.zoomScale = self.scrollView.frame.size.width / image.size.width;
            } else {
                NSLog(@"Failed to load photo with url %@", url);
                // TODO: Log more info about _why_ the image reqest failed
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                    message:@"Could not download image"
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                [alertView show];
            }
        });
    });
}

- (void)handleImageDoubleTap:(id)thing {
    CGFloat zoomScale = self.scrollView.frame.size.width / self.imageView.image.size.width;
    [self.scrollView setZoomScale:zoomScale animated:YES];
}

- (void)viewDidLoad
{
    self.imageView.userInteractionEnabled = YES;
    self.scrollView.delegate = (id)self;

    UITapGestureRecognizer *imageDoubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleImageDoubleTap:)];
    imageDoubleTap.numberOfTapsRequired = 2;
    [self.imageView addGestureRecognizer:imageDoubleTap];

    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    return [self imageView];
}

- (IBAction)reportInappropriate:(id)sender
{
    NSDictionary *photo = [OTMTreeDictionaryHelper getLatestPhotoInDictionary:self.data];
    OTMInappropriateContentMailViewController *mailViewController =
        [[OTMInappropriateContentMailViewController alloc] initWithPhotoDictionary:photo];
    mailViewController.mailComposeDelegate = self;
    [self presentModalViewController:mailViewController animated:YES];
}

# pragma mark MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [self dismissModalViewControllerAnimated:YES];
}

@end
