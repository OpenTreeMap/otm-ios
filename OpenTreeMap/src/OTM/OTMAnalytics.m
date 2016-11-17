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

#import "OTMAnalytics.h"
#import "GAI.h"
#import "GAIFields.h"
#import "GAIDictionaryBuilder.h"

@implementation OTMAnalytics

- (OTMAnalytics *)init {
    self = [super init];
    if (self) {
        NSString *trackingId = [[OTMEnvironment sharedEnvironment] appGoogleAnalyticsId];
        if (trackingId) {
            [[GAI sharedInstance] trackerWithTrackingId:trackingId];
            //[[GAI sharedInstance].logger setLogLevel:kGAILogLevelVerbose];
        } else {
            NSLog(@"Skipping Google Analytics initialization - No tracking ID configured");
        }
    }
    return self;
}

-(void)sendScreenView:(NSString *)screenName
{
    id tracker = [self getUpdatedTracker];
    [tracker set:kGAIScreenName value:screenName];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}

-(id)getUpdatedTracker {
    id tracker = [[GAI sharedInstance] defaultTracker];

    OTMUser * user = [[SharedAppDelegate loginManager] loggedInUser];
    NSString * userId = user ? [NSString stringWithFormat:@"%d", user.userId] : nil;
    [tracker set:kGAIUserId value:userId];
    
    NSString * urlName = [[OTMEnvironment sharedEnvironment] instance];
    [tracker set:kGAIAppName value:urlName];
    
    return tracker;
}

@end
