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

#import "OTMAPI.h"

/**
 * OTM2 API Provides a functional wrapper around the OpenTreeMap API
 *
 * This is a singleton object - grab it from the OTMEnvironment
 */
@interface OTM2API : OTMAPI {
}

@property (nonatomic,strong) NSString* currentGeoRev;

-(void)loadInstanceInfo:(NSString*)instance
           withCallback:(AZJSONCallback)callback;

-(NSString *)tileUrlTemplateForInstanceId:(NSString *)iid
                                   geoRev:(NSString *)rev
                                    layer:(NSString *)layer;

@end
