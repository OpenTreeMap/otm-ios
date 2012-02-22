//
//  OTMAppDelegate.m
//  OpenTreeMap
//
//  Created by Robert Cheetham on 2/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OTMAppDelegate.h"
#import "OTMEnvironment.h"
#import "Three20Network/Three20Network.h"

@interface OTMAppDelegate()
    /**
     Setup the shared TTURLCache by reading settings from the shared OTMEnvironment
     */
    - (void)configureGlobalRequestQueueAndUrlCache;
@end

@implementation OTMAppDelegate

@synthesize window = _window;

#pragma mark UIApplicationDelegate methods

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self configureGlobalRequestQueueAndUrlCache];
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark TTURLCache helpers

- (void)configureGlobalRequestQueueAndUrlCache
{
    OTMEnvironment *env = [OTMEnvironment sharedEnvironment];

    TTURLRequestQueue *queue = [[TTURLRequestQueue alloc] init];
    [queue setMaxContentLength:[[env urlCacheQueueMaxContentLength] intValue]];
    [TTURLRequestQueue setMainQueue:queue];

    TTURLCache *cache = [[TTURLCache alloc] initWithName:[env urlCacheName]];
    [cache setInvalidationAge:[[env urlCacheInvalidationAgeInSeconds] floatValue]];
    [TTURLCache setSharedCache:cache];
}


@end
