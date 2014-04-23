//
//  OTMEULAViewController.m
//  OpenTreeMap
//
//  Created by Adam Hinz on 4/22/14.
//
//

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
