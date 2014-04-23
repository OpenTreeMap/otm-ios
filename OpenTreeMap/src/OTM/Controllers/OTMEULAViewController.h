//
//  OTMEULAViewController.h
//  OpenTreeMap
//
//  Created by Adam Hinz on 4/22/14.
//
//

#import <UIKit/UIKit.h>
#import "OTMRegistrationViewController.h"

@interface OTMEULAViewController : UIViewController

@property (nonatomic) BOOL loaded;
@property (nonatomic, strong) OTMRegistrationViewController *regController;
@property (nonatomic, strong) IBOutlet UIWebView *webview;

-(void)loadWebview;
-(IBAction)acceptEULA:(id)sender;
-(IBAction)rejectEULA:(id)sender;

@end
