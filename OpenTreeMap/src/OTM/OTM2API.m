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
  [self.request get:@":instance"
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

@end
