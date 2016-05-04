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

#import "OTMAppDelegate.h"
#import "OTMEnvironment.h"
#import "OTMPreferences.h"
#import <Rollbar/Rollbar.h>

@interface OTMAppDelegate()

@end

@implementation OTMAppDelegate

@synthesize window = _window, keychain, loginManager, mapRegion, mapMode;

#pragma mark UIApplicationDelegate methods

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    keychain = [[AZKeychainItemWrapper alloc] initWithIdentifier:@"org.otm.creds"
                                                     accessGroup:nil];

    loginManager = [[OTMLoginManager alloc] init];

    [[OTMPreferences sharedPreferences] load];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeMapMode:) name:kOTMChangeMapModeNotification object:nil];


    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeEnvironment:) name:kOTMEnvironmentChangeNotification object:nil];

    if ([self configureRollbarWithEnvironment:[OTMEnvironment sharedEnvironment]])
    {
        [Rollbar debugWithMessage:@"iOS application launched"];
    }

    return YES;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state.
    // This can occur for certain types of temporary interruptions (such as an
    // incoming phone call or SMS message) or when the user quits the
    // application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down
    // OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[OTMPreferences sharedPreferences] save];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [[OTMPreferences sharedPreferences] load];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the
    // application was inactive. If the application was previously in the
    // background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


#pragma mark NSNotification handlers

-(void)changeMapMode:(NSNotification *)note {
    self.mapMode = [note.object intValue];
}

-(void)changeEnvironment:(NSNotification *)note {
    OTMEnvironment *env = note.object;
    self.window.tintColor = env.primaryColor;
    self.window.backgroundColor = [UIColor whiteColor];
}

#pragma mark Helpers

- (BOOL) configureRollbarWithEnvironment:(OTMEnvironment*)env
{
    NSString *rollbarClientAccessToken = [env rollbarClientAccessToken];
    if (rollbarClientAccessToken) {
        RollbarConfiguration *config = [RollbarConfiguration configuration];
        config.environment = env.environmentName ?: config.environment;
        [Rollbar initWithAccessToken:rollbarClientAccessToken configuration:config];
        return YES;
    } else {
        NSLog(@"Skipping Rollbar initialization - No client access token configured");
        return NO;
    }
}

@end
