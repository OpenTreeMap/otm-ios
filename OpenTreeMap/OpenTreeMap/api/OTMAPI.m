//                                                                                                                
// Copyright (c) 2012 Azavea                                                                                
//                                                                                                                
// Permission is hereby granted, free of charge, to any person obtaining a copy                                   
// of this software and associated documentation files (the "Software"), to                                       
// deal in the Software without restriction, including without limitation the                                     
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or                                    
//  sell copies of the Software, and to permit persons to whom the Software is                                    
// furnished to do so, subject to the following conditions:                                                       
//                                                                                                                
// The above copyright notice and this permission notice shall be included in                                     
// all copies or substantial portions of the Software.                                                            
//                                                                                                                
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR                                     
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,                                       
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE                                    
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER                                         
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,                                  
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN                                      
// THE SOFTWARE.                                                                                                  
//    

#import "OTMAPI.h"
#import "ASIHTTPRequest.h"
#import "OTMReverseGeocodeOperation.h"
#import "AZPointCollection.h"
#import "AZTileQueue.h"

@interface OTMAPI()
+(int)parseSection:(NSData*)data 
            offset:(uint32_t)offset 
            points:(CFMutableArrayRef)points
             error:(NSError**)error;

+(ASIRequestCallback)liftResponse:(AZGenericCallback)callback;
+(AZGenericCallback)jsonCallback:(AZGenericCallback)callback;

@end

@implementation OTMAPI

@synthesize request, tileRequest, tiles, renders;

+(ASIRequestCallback)liftResponse:(AZGenericCallback)callback {
    if (callback == nil) { return [^(id obj, id error) {} copy]; }
    return [^(ASIHTTPRequest* req) {
        if (req.responseStatusCode >= 200 && req.responseStatusCode <= 299) {
            callback([req responseData], nil);
        } else {
            NSString *responseBodyAsString = [[NSString alloc] initWithData:[req responseData] encoding:NSUTF8StringEncoding];
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                req.url, @"url",
                req.requestMethod, @"method",
                responseBodyAsString, @"body",
                [NSNumber numberWithInt:req.responseStatusCode], @"statusCode",
                nil];
            NSError* error = [[NSError alloc] initWithDomain:@"otm"
                                                        code:req.responseStatusCode
                                                    userInfo:userInfo];
            callback(nil, error);
        }
    } copy];
}

+(AZGenericCallback)jsonCallback:(AZGenericCallback)callback {
    if (callback == nil) { return [^(id obj, id error) {} copy]; }
    return [^(NSData* data, NSError* error) {
            if (error) {
                callback(nil, error);
            } else {
                NSError* error = nil;
            
                id json = [NSJSONSerialization JSONObjectWithData:data
                                                          options:0
                                                            error:&error];    
                callback(json, error);
            }
    } copy];
}

-(id)init {
    if ((self = [super init])) {
        tiles = [[AZTileQueue alloc] init];
        tiles.api = self;
        tiles.opQueue = [[NSOperationQueue alloc] init];
        tiles.opQueue.maxConcurrentOperationCount = 3;

        renders = [[AZTileQueue alloc] init];
        renders.opQueue = [[NSOperationQueue alloc] init];
        renders.opQueue.maxConcurrentOperationCount = 2;
    }
    return self;
}

-(void)setVisibleMapRect:(MKMapRect)r{
    [renders setVisibleMapRect:r];
    [tiles setVisibleMapRect:r];
}

-(void)setZoomScale:(MKZoomScale)z {
    [renders setZoomScale:z];
    [tiles setZoomScale:z];
}

-(void)getSpeciesListWithCallback:(AZJSONCallback)callback {
    if (species != nil) {
        if (callback) {
            callback(species, nil);
        }
    } else {
        [self.request get:@"species"
                   params:nil
                 callback:[OTMAPI liftResponse:
                           [OTMAPI jsonCallback:^(id json, NSError *err) {
                     if (err != nil) {
                         if (callback) { callback(nil, err); }
                     } else {
                         NSMutableDictionary *s = [NSMutableDictionary dictionary];
                         
                         [json enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                             [s setObject:[obj objectForKey:@"id"]
                                   forKey:[obj objectForKey:@"common_name"]];
                         }];
                         species = s;
                         if (callback) { callback(species, nil); }
                     }
                 }]]];
                           
    }
}

-(void)getPlotsNearLatitude:(double)lat longitude:(double)lon callback:(AZJSONCallback)callback {
    [self getPlotsNearLatitude:lat longitude:lon maxResults:1 callback:callback];
}

-(void)getPlotsNearLatitude:(double)lat longitude:(double)lon filters:(OTMFilters *)filters callback:(AZJSONCallback)callback {
    [self getPlotsNearLatitude:lat longitude:lon maxResults:1 filters:filters callback:callback];
}

-(void)getPlotsNearLatitude:(double)lat longitude:(double)lon maxResults:(NSUInteger)max callback:(AZJSONCallback)callback {
    [self getPlotsNearLatitude:lat longitude:lon maxResults:max filters:nil callback:callback];
}

-(void)getPlotsNearLatitude:(double)lat longitude:(double)lon maxResults:(NSUInteger)max filters:(OTMFilters *)filters callback:(AZJSONCallback)callback {

    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   [NSString stringWithFormat:@"%f", lat], @"lat",
                                   [NSString stringWithFormat:@"%f", lon], @"lon",
                                   [NSNumber numberWithInt:max], @"max_plots", nil];

    if (filters != nil) {
        [params addEntriesFromDictionary:[filters customFiltersDict]];
    }

    [self.request get:@"locations/:lat,:lon/plots" 
               params:params
             callback:[OTMAPI liftResponse:
                       [OTMAPI jsonCallback:callback]]];
}

-(void)getImageForTree:(int)plotid photoId:(int)photoid callback:(AZImageCallback)callback {
    [self.request getRaw:@"plots/:plot/tree/photo/:photo" 
                  params:[NSDictionary dictionaryWithObjectsAndKeys:
                          [NSString stringWithFormat:@"%d", plotid], @"plot",
                          [NSString stringWithFormat:@"%d", photoid], @"photo", nil]
                    mime:@"image/jpeg"
                callback:[OTMAPI liftResponse:^(id data, NSError* error) { 
                    if (callback) {
                        if (error != nil) { 
                            callback(nil, error);
                        } else {
                            callback([UIImage imageWithData:data], nil);
                        }
                    }
                }]];
}

-(void)getPointOffsetsInTile:(MKCoordinateRegion)region 
                     filters:(OTMFilters *)filters
                     mapRect:(MKMapRect)mapRect
                   zoomScale:(MKZoomScale)zoomScale 
                    callback:(AZPointDataCallback)callback {

    [tiles queueRequest:[[AZTileRequest alloc] initWithRegion:region
                                                      mapRect:mapRect
                                                    zoomScale:zoomScale
                                                      filters:filters
                                                     callback:callback
                                                    operation:^(AZTileRequest *r) {
                    [self performGetPointOffsetsInTile:r.region
                                               filters:r.filters
                                               mapRect:r.mapRect
                                             zoomScale:r.zoomScale
                                              callback:r.callback];
            }]];
                                        
}

-(void)performGetPointOffsetsInTile:(MKCoordinateRegion)region 
                            filters:(OTMFilters *)filters
                            mapRect:(MKMapRect)mapRect
                          zoomScale:(MKZoomScale)zoomScale 
                           callback:(AZPointDataCallback)callback {
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                         [NSString stringWithFormat:@"%f,%f,%f,%f", 
                                                                   region.center.longitude - region.span.longitudeDelta / 2.0,
                                                                   region.center.latitude - region.span.latitudeDelta / 2.0,
                                                                   region.center.longitude + region.span.longitudeDelta / 2.0,
                                                                   region.center.latitude + region.span.latitudeDelta / 2.0, 
                                                                   nil], @"bbox", nil];

    [params addEntriesFromDictionary:[filters customFiltersDict]];

    [self.tileRequest getRaw:@"tiles"
                  params:params
                    mime:@"otm/trees"
                callback:[OTMAPI liftResponse:^(id data, NSError* error) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    if (error != nil) { callback(nil, error); return; }
                    uint32_t magic = 0;
                    
                    if ([data length] < 8) {
                        // Signal error? Invalid datastream (too small)
                        NSError* myError = [[NSError alloc] initWithDomain:@"otm.parse" 
                                                                      code:0  
                                                                  userInfo:[NSDictionary dictionaryWithObject:@"Header too short" forKey:@"error"]];
                        
                        callback(nil, myError);
                        return;
                    }
                    
                    [data getBytes:&magic length:4];
                    
                    uint32_t length = 0;
                    uint32_t offset = 4;
                    
                    CFMutableArrayRef points = CFArrayCreateMutable(NULL, length, NULL);
                    
                    [data getBytes:&length range:NSMakeRange(offset, 4)];
                    offset += 4;
                    
                    if (magic != 0xA3A5EA00) {
                        NSError* myError = [[NSError alloc] initWithDomain:@"otm.parse" 
                                                                      code:0  
                                                                  userInfo:[NSDictionary dictionaryWithObject:@"Bad magic number (not 0xA3A5EA00)" forKey:@"error"]];
                        
                        callback(nil, myError);
                        return;
                    }
                    
                    NSError* sectionError = NULL;
                    
                    while(offset < [data length] && CFArrayGetCount(points) < length) {
                        offset = [OTMAPI parseSection:data offset:offset points:points error:&sectionError];
                        
                        if (sectionError != NULL) {
                            
                            callback(nil, sectionError);
                            return;
                        }
                    }
            
                    AZPointCollection *pcol = [[AZPointCollection alloc] initWithMapRect:mapRect
                                                                               zoomScale:zoomScale
                                                                                  points:points];
            
                    callback(pcol, nil);
                    
                    CFRelease(points);
                    points = NULL;
        });
                }]];        
}

+(int)parseSection:(NSData*)data    
            offset:(uint32_t)offset 
            points:(CFMutableArrayRef)points
             error:(NSError**)error {
    
    // Each section contains a simple header:
    // [1 byte type][2 byte length           ][1 byte pad]
    uint32_t sectionLength = 0;
    uint32_t sectionType = 0;
    
    [data getBytes:&sectionType range:NSMakeRange(offset, 1)];
    offset += 1;
    
    [data getBytes:&sectionLength range:NSMakeRange(offset, 2)];
    offset += 2;
    offset += 1; // Skip padding
    
    for(int i=0;i<sectionLength;i++) {
        OTMPoint* const p = malloc(sizeof(OTMPoint));
        p->xoffset = 0;
        p->yoffset = 0;
        p->style = sectionType;
        
        [data getBytes:&(p->xoffset) range:NSMakeRange(offset, 1)];
        offset += 1;
        
        [data getBytes:&(p->yoffset) range:NSMakeRange(offset, 1)];
        offset += 1;
        
        p->style = sectionType;
        
        CFArrayAppendValue(points, p);
    }
    
    
    return offset;   
}

-(void)savePlot:(NSDictionary *)plot withUser:(OTMUser *)user callback:(AZJSONCallback)callback {
    id pId = [plot objectForKey:@"id"];
    
    // Update (PUT)
    if (pId != nil) {
        
    } else {
        // POST
    }
}

-(void)logUserIn:(OTMUser*)user callback:(AZUserCallback)callback {
    [request get:@"login" 
        withUser:user 
          params:nil 
        callback:[OTMAPI liftResponse:[OTMAPI jsonCallback:^(id json, NSError* error) {
        if (error) {
            [user setLoggedIn:NO];
            if (error.code == 401) {
                callback(nil, kOTMAPILoginResponseInvalidUsernameOrPassword);
            } else {
                callback(nil, kOTMAPILoginResponseError);
            }
        } else {
            user.email = [json objectForKey:@"email"];
            user.firstName = [json objectForKey:@"firstname"];
            user.lastName = [json objectForKey:@"lastname"];
            user.userId = [[json valueForKey:@"id"] intValue];
            user.zipcode = [json objectForKey:@"zipcode"];
            user.reputation = [[json valueForKey:@"reputation"] intValue];
            [user setLoggedIn:YES];
            callback(user, kOTMAPILoginResponseOK);
        }
    }]]];
    
}

-(void)resetPasswordForEmail:(NSString*)email callback:(AZJSONCallback)callback {
    [request post:@"login/reset_password"
           params:[NSDictionary dictionaryWithObject:email forKey:@"email"]
             data:nil
         callback:[OTMAPI liftResponse:[OTMAPI jsonCallback:callback]]];
        
}

-(NSData *)encodeUser:(OTMUser *)user {
    NSMutableDictionary *userDict = [NSMutableDictionary dictionary];
    [userDict setObject:user.username forKey:@"username"];
    [userDict setObject:user.firstName forKey:@"firstname"];
    [userDict setObject:user.lastName forKey:@"lastname"];
    [userDict setObject:user.email forKey:@"email"];
    [userDict setObject:user.password forKey:@"password"];
    [userDict setObject:user.zipcode forKey:@"zipcode"];
    
    return [self jsonEncode:userDict];
}

-(NSData *)jsonEncode:(id)obj {
    NSError *error = NULL;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:obj options:0 error:&error];
    if (error != NULL) {
        NSLog(@"[ERROR] Could not encode \"%@\" as json (error: %@)",obj,error);
    }
    
    return jsonData;
}

-(void)setProfilePhoto:(OTMUser *)user callback:(AZJSONCallback)callback {
    [request post:@"user/:user_id/photo/profile"
         withUser:user
           params:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:user.userId]
                                              forKey:@"user_id"]
             data:UIImagePNGRepresentation(user.photo) 
         callback:[OTMAPI liftResponse:[OTMAPI jsonCallback:callback]]];
}

-(void)setPhoto:(UIImage *)image onPlotWithID:(NSUInteger)pId withUser:(OTMUser *)user callback:(AZJSONCallback)cb {
    [request post:@"plots/:plot_id/tree/photo"
         withUser:user
           params:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:pId]
                                              forKey:@"plot_id"]
             data:UIImagePNGRepresentation(image) 
         callback:[OTMAPI liftResponse:[OTMAPI jsonCallback:cb]]];    
}

-(void)createUser:(OTMUser *)user callback:(AZUserCallback)callback {
    [request post:@"user/"
           params:nil
             data:[self encodeUser:user]
         callback:[OTMAPI liftResponse:[OTMAPI jsonCallback:^(NSDictionary *json, NSError *error) 
    {
        if (callback != nil) {
            if (error != nil) {
               callback(user, kOTMAPILoginResponseError);
            } else {
                if ([[json objectForKey:@"status"] isEqualToString:@"success"]) {
                    user.userId = [[json valueForKey:@"id"] intValue];
                    callback(user, kOTMAPILoginResponseOK);
                } else {
                    callback(user, kOTMAPILoginResponseError);
                }
            }
        }
    }]]];
}

-(void)changePasswordForUser:(OTMUser *)user to:(NSString *)newPass callback:(AZUserCallback)callback {
    [request put:@"user/:user_id/password"
        withUser:user
          params:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:user.userId]
                                             forKey:@"user_id"]
            data:[self jsonEncode:[NSDictionary dictionaryWithObject:newPass forKey:@"password"]]
        callback:[OTMAPI liftResponse:[OTMAPI jsonCallback:^(NSDictionary *json, NSError *error) 
        {        
            if (callback != nil) {
                if (error != nil) {
                    callback(user, kOTMAPILoginResponseError);
                } else {
                    if ([[json objectForKey:@"status"] isEqualToString:@"success"]) {
                        user.password = newPass;
                        callback(user, kOTMAPILoginResponseOK);
                    } else {
                        callback(user, kOTMAPILoginResponseError);
                    }
                }
            }
        }]]];
        
}

-(void)getRecentActionsForUser:(OTMUser *)user callback:(AZJSONCallback)callback {
    [self getRecentActionsForUser:user offset:0 length:5 callback:callback];
}

-(void)getRecentActionsForUser:(OTMUser *)user offset:(NSUInteger)offset callback:(AZJSONCallback)callback {
    [self getRecentActionsForUser:user offset:offset length:5 callback:callback];
}

-(void)getRecentActionsForUser:(OTMUser *)user offset:(NSUInteger)offset length:(NSUInteger)length callback:(AZJSONCallback)callback {
    [request get:@"user/:user_id/edits"
        withUser:user
          params:[NSDictionary
                  dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:user.userId],
                                                @"user_id",
                                                [NSNumber numberWithInt:offset],
                                                @"offset", 
                                                [NSNumber numberWithInt:length],
                                                @"length", nil]
        callback:[OTMAPI liftResponse:[OTMAPI jsonCallback:callback]]];
}

-(void)geocodeAddress:(NSString *)address callback:(AZJSONCallback)callback
{
    NSString *urlEncodedSearchText = [address stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [request get:@"addresses/:address"
          params:[NSDictionary dictionaryWithObject:urlEncodedSearchText forKey:@"address"]
        callback:[OTMAPI liftResponse:[OTMAPI jsonCallback:callback]]];
}

-(void)reverseGeocodeCoordinate:(CLLocationCoordinate2D)coordinate callback:(AZGenericCallback)callback
{
    if (!geocodeQueue) {
        geocodeQueue = [[NSOperationQueue alloc] init];
        [geocodeQueue setMaxConcurrentOperationCount:1];
    }

    OTMReverseGeocodeOperation *operation = [[OTMReverseGeocodeOperation alloc] initWithCoordinate:coordinate callback:callback];

    [geocodeQueue addOperation:operation];
}

-(void)addPlotWithOptionalTree:(NSDictionary *)details user:(OTMUser *)user callback:(AZJSONCallback)callback
{
    [request post:@"plots"
         withUser:user
           params:nil
             data:[self jsonEncode:details]
         callback:[OTMAPI liftResponse:[OTMAPI jsonCallback:callback]]];
}

-(void)updatePlotAndTree:(NSDictionary *)details user:(OTMUser *)user callback:(AZJSONCallback)callback
{
    if ([details objectForKey:@"id"] == nil) {
        if (callback) {
            callback(nil, [NSError errorWithDomain:@"No id specified in details dictionary" code:0 userInfo:details]);
        }
    }
    [request put:@"plots/:id"
        withUser:user
          params:[NSDictionary dictionaryWithObject:[details objectForKey:@"id"] forKey:@"id"]
            data:[self jsonEncode:details]
        callback:[OTMAPI liftResponse:[OTMAPI jsonCallback:callback]]];
}

@end
