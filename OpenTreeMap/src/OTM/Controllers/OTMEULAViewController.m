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

#import "OTMEULAViewController.h"

@interface OTMEULAViewController ()

@end

@implementation OTMEULAViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self loadWebview];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self loadWebview];
}

- (void)loadWebview {
    if (!self.loaded) {
        self.webview.delegate = self;
        [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.opentreemap.org/terms-of-service/"]]];
        self.loaded = YES;
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self.webview stringByEvaluatingJavaScriptFromString:@"document.getElementsByClassName('header')[0].remove()"];
    [self.webview stringByEvaluatingJavaScriptFromString:@"document.getElementsByClassName('navbar')[0].remove()"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)acceptEULA:(id)sender {
    [self.regController createNewUser];
}

-(IBAction)rejectEULA:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];

}

-(void)dealloc {
    self.webview.delegate = nil;
}

@end
