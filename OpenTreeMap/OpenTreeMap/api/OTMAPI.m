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

typedef void(^AZGenericCallback)(id obj, NSError* error);

@interface OTMAPI()
+(int)parseSection:(NSData*)data 
            offset:(uint32_t)offset 
            points:(CFMutableArrayRef)points
             error:(NSError**)error;

+(ASIRequestCallback)liftResponse:(AZGenericCallback)callback;
+(AZGenericCallback)jsonCallback:(AZGenericCallback)callback;

@end

@implementation OTMAPI

@synthesize request;

+(ASIRequestCallback)liftResponse:(AZGenericCallback)callback {
    if (callback == nil) { return [^(id obj, id error) {} copy]; }
    return [^(ASIHTTPRequest* req) {
        if (req.responseStatusCode >= 200 && req.responseStatusCode <= 299) {
            callback([req responseData], nil);
        } else {
            NSError* error = [[NSError alloc] initWithDomain:@"otm"
                                                        code:req.responseStatusCode
                                                    userInfo:nil];
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

-(void)getPlotsNearLatitude:(double)lat longitude:(double)lon callback:(AZJSONCallback)callback {
    [self.request get:@"locations/:lat,:lon/plots" 
               params:[NSDictionary dictionaryWithObjectsAndKeys:
                       [NSString stringWithFormat:@"%f", lat], @"lat",
                       [NSString stringWithFormat:@"%f", lon], @"lon", nil]
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

-(void)getPointOffsetsInTile:(MKCoordinateRegion)region callback:(AZPointDataCallback)callback {
    [self.request getRaw:@"tiles"
                  params:[NSDictionary dictionaryWithObjectsAndKeys:
                          [NSString stringWithFormat:@"%f,%f,%f,%f", 
                           region.center.longitude - region.span.longitudeDelta / 2.0,
                           region.center.latitude - region.span.latitudeDelta / 2.0,
                           region.center.longitude + region.span.longitudeDelta / 2.0,
                           region.center.latitude + region.span.latitudeDelta / 2.0, 
                           nil], @"bbox", nil]
                    mime:@"otm/trees"
                callback:[OTMAPI liftResponse:^(id data, NSError* error) {
                    if (error != nil) { callback(nil, error); return; }
                    uint32_t magic = 0;
                    
                    if ([data length] < 12) {
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
                    
                    callback(points, nil);
                    
                    for(int i=0;i<CFArrayGetCount(points);i++) {
                        free((void *)CFArrayGetValueAtIndex(points, i));
                    }
                    
                    CFRelease(points);
                    points = NULL;
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
        
        [data getBytes:&(p->xoffset) range:NSMakeRange(offset, 1)];
        offset += 1;
        
        [data getBytes:&(p->yoffset) range:NSMakeRange(offset, 1)];
        offset += 1;
        
        p->style = sectionType;
        
        CFArrayAppendValue(points, p);
    }
    
    
    return offset;   
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
    return [NSJSONSerialization dataWithJSONObject:obj options:0 error:NULL];
}

-(void)setProfilePhoto:(OTMUser *)user callback:(AZJSONCallback)callback {
    [request post:@"user/:user_id/photo/profile.png"
         withUser:user
           params:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:user.userId]
                                              forKey:@"user_id"]
             data:UIImagePNGRepresentation(user.photo) 
         callback:[OTMAPI liftResponse:[OTMAPI jsonCallback:callback]]];
}

-(void)createUser:(OTMUser *)user callback:(AZUserCallback)callback {
    [request post:@"login/create_user"
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

@end
