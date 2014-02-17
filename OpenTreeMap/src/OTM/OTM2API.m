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

#import "OTM2API.h"
#import "OTMAPI.h"
#import "OTMEnvironment.h"

@interface OTM2API()
@end

@implementation OTM2API

-(void)loadInstanceInfo:(NSString*)instance
           withCallback:(AZJSONCallback)callback {
  [self loadInstanceInfo:instance
                 forUser:[[SharedAppDelegate loginManager] loggedInUser]
            withCallback:callback];
}

-(void)loadInstanceInfo:(NSString*)instance
                forUser:(AZUser*)user
           withCallback:(AZJSONCallback)callback {

  [self.noPrefixRequest get:@":instance"
               withUser:user
                 params:@{@"instance" : instance}
               callback:[OTMAPI liftResponse:
                                  [OTMAPI jsonCallback:callback]]];

}

-(NSString *)tileUrlTemplateForInstanceId:(NSString *)iid
                                   geoRev:(NSString *)rev
                                    layer:(NSString *)layer {
    return [NSString stringWithFormat:
                         @"/tile/%@/database/otm/table/%@/{z}/{x}/{y}.png?instance_id=%@&scale={scale}", rev, layer, iid];
}

-(void)logUserIn:(OTMUser*)user callback:(AZUserCallback)callback {
    [self.noPrefixRequest get:@"login"
                 withUser:user
                   params:nil
                 callback:[OTMAPI liftResponse:[OTMAPI jsonCallback:^(id json, NSError* error) {
            if (error) {
              [user setLoggedIn:NO];
              if (error.code == 401) {
                callback(nil, nil, kOTMAPILoginResponseInvalidUsernameOrPassword);
              } else {
                callback(nil, nil, kOTMAPILoginResponseError);
              }
            } else {
              user.email = [json objectForKey:@"email"];
              user.firstName = [json objectForKey:@"firstname"];
              user.lastName = [json objectForKey:@"lastname"];
              user.userId = [[json valueForKey:@"id"] intValue];
              user.zipcode = [json objectForKey:@"zipcode"];
              user.reputation = [[json valueForKey:@"reputation"] intValue];
              user.permissions = [json objectForKey:@"permissions"];
              user.level = [[[json objectForKey:@"user_type"] valueForKey:@"level"] intValue];
              user.userType = [[json objectForKey:@"user_type"] objectForKey:@"name"];
              [user setLoggedIn:YES];

              [self loadInstanceInfo:[[OTMEnvironment sharedEnvironment] instance]
                             forUser:user
                        withCallback:^(id json, NSError *error) {
                  [[OTMEnvironment sharedEnvironment] updateEnvironmentWithDictionary:json];
                  callback(user, json, kOTMAPILoginResponseOK);
                }];
            }
                }]]];

}

@end
