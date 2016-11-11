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

#import "OTMAboutViewController.h"

@interface OTMAboutViewController ()

@end

@implementation OTMAboutViewController

@synthesize backgroundImageView, webView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.screenName = @"About";  // for Google Analytics
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    backgroundImageView.image = [UIImage imageNamed:@"about_bg"];

    webView.opaque = YES;

    NSString *aboutPagePath = [[NSBundle mainBundle] pathForResource:@"about" ofType:@"html"];
    if (aboutPagePath) {
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:aboutPagePath error:nil];
        long long fileSize = [[fileAttributes valueForKey:@"NSFileSize"] longLongValue];
        // We are checking file size here because the some skins will use an HTML page and some
        // will just use the static background image. Since the HTML is referenced by the project,
        // it cannot be omitted, so skins that do not use about.html will just have an empty
        // file, or one with a short comment.
        if (fileSize > 64) {
            CGRect f = self.view.frame;
            webView.frame = CGRectMake(0, 20, f.size.width, f.size.height - 60);
            NSURL *url = [NSURL fileURLWithPath:aboutPagePath];
            NSString *html = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
            [webView loadHTMLString:html baseURL:[url URLByDeletingLastPathComponent]];
        } else {
            NSLog(@"about.html was less than 64 bytes in size. Hiding the about UIWebView.");
            webView.hidden = YES;
        }
    } else {
        NSLog(@"about.html was not found in the bundle. Hiding the about UIWebView.");
        webView.hidden = YES;
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)viewWillAppear:(BOOL)animated {
    // The about view does not need the user's location. Save the battery by turning off location updates.
    // We can not depend on order of viewWillAppear: and viewWillDisappear: calls when transitioning
    // between views. We would prefer to put these stopUpdatingLocation calls in the viewWillDisappear: method
    // of the view controllers that need location data, but we can't.
    [[SharedAppDelegate locationManager] stopUpdatingLocation];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark UIWebView Delegate methods

-(BOOL) webView:(UIWebView *)inWeb shouldStartLoadWithRequest:(NSURLRequest *)inRequest navigationType:(UIWebViewNavigationType)inType {
    // Open links in Mobile Safari
    if ( inType == UIWebViewNavigationTypeLinkClicked ) {
        [[UIApplication sharedApplication] openURL:[inRequest URL]];
        return NO;
    }

    return YES;
}

@end
