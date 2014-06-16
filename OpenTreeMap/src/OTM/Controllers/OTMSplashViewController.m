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

#import "OTMSplashViewController.h"
#import "OTMPreferences.h"

@interface OTMSplashViewController ()

@end

@implementation OTMSplashViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)loadInstance {
    OTMLoginManager* loginManager = [SharedAppDelegate loginManager];
    AZUser* user = [loginManager loggedInUser];

    OTM2API *api = [[OTMEnvironment sharedEnvironment] api2];
    NSString *instance = [[OTMEnvironment sharedEnvironment] instance];
    [api loadInstanceInfo:instance
                  forUser:user
             withCallback:^(id json, NSError *error) {

        if (error != nil) {
          [UIAlertView showAlertWithTitle:nil
                                  message:@"There was a problem connecting to the server. Hit OK to try again."
                        cancelButtonTitle:@"OK"
                         otherButtonTitle:nil
                                 callback:^(UIAlertView *alertView, int btnIdx)
                       {
                         [self loadInstance];
                       }];
        } else {
          [[OTMEnvironment sharedEnvironment] updateEnvironmentWithDictionary:json];
            [self afterSplashDelaySegueTo:@"startWithInstance"];
        }
      }];
}

- (void)afterSplashDelaySegueTo:(NSString *)segueName
{
    NSTimeInterval seconds = self.triggerTime - [[NSDate date] timeIntervalSince1970];

    dispatch_time_t tgt = dispatch_time(DISPATCH_TIME_NOW, seconds * NSEC_PER_SEC);
    dispatch_after(tgt, dispatch_get_main_queue(), ^{
        [self performSegueWithIdentifier:segueName sender:self];
    });
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSTimeInterval seconds = [[OTMEnvironment sharedEnvironment] splashDelayInSeconds];
    self.triggerTime = [[NSDate date] timeIntervalSince1970] + seconds;

    NSString *instance = [[OTMEnvironment sharedEnvironment] instance];

    if ([[OTMEnvironment sharedEnvironment] allowInstanceSwitch]) {
        instance = [[OTMPreferences sharedPreferences] instance];
        if (instance && ![instance isEqualToString:@""]) {
            [[OTMEnvironment sharedEnvironment] setInstance:instance];
            [self loadInstance];
        } else {
            [self afterSplashDelaySegueTo:@"selectInstance"];
        }

    } else {
       [self loadInstance];
    }

}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
