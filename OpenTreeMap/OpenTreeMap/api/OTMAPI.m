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

@interface OTMAPI()
+(int)parseSection:(NSData*)data 
            offset:(uint32_t)offset 
            points:(CFMutableArrayRef)points
             error:(NSError**)error;

+(ASIRequestCallback)jsonCallback:(AZJSONCallback)callback;

@end

@implementation OTMAPI

@synthesize request;

+(ASIRequestCallback)jsonCallback:(AZJSONCallback)callback {
    return [^(id req) {
        if (callback != nil) {
            NSError* error = nil;
            id jsonp = [NSJSONSerialization JSONObjectWithData:[req responseData]
                                                       options:0
                                                         error:&error];    
            callback(jsonp, error);
        }
    } copy];
}

-(void)getPlotsNearLatitude:(double)lat longitude:(double)lon callback:(AZJSONCallback)callback {
    [self.request get:@"locations/:lat,:lon/plots" 
               params:[NSDictionary dictionaryWithObjectsAndKeys:
                       [NSString stringWithFormat:@"%f", lat], @"lat",
                       [NSString stringWithFormat:@"%f", lon], @"lon", nil]
             callback:[OTMAPI jsonCallback:callback]];
}

-(void)getImageForTree:(int)plotid photoId:(int)photoid callback:(AZImageCallback)callback {
    [self.request getRaw:@"plots/:plot/tree/photo/:photo" 
                  params:[NSDictionary dictionaryWithObjectsAndKeys:
                          [NSString stringWithFormat:@"%d", plotid], @"plot",
                          [NSString stringWithFormat:@"%d", photoid], @"photo", nil]
                    mime:@"image/jpeg"
                callback:^(id req) { 
                    if (callback) {
                        callback([UIImage imageWithData:[req responseData]], nil);
                    }
                }];
}

-(void)getPointOffsetsInTile:(MKCoordinateRegion)region callback:(AZPointDataCallback)callback error:(NSError**)error {
    [self.request getRaw:@"tiles"
                  params:[NSDictionary dictionaryWithObjectsAndKeys:
                          [NSString stringWithFormat:@"%f,%f,%f,%f", 
                           region.center.longitude - region.span.longitudeDelta / 2.0,
                           region.center.latitude - region.span.latitudeDelta / 2.0,
                           region.center.longitude + region.span.longitudeDelta / 2.0,
                           region.center.latitude + region.span.latitudeDelta / 2.0, 
                           nil], @"bbox", nil]
                    mime:@"otm/trees"
                callback:^(id req) { 
                    NSData* data = [req responseData];
                    uint32_t magic = 0;
                    
                    if ([data length] < 12) {
                        // Signal error? Invalid datastream (too small)
                        NSError* myError = [[NSError alloc] initWithDomain:@"otm.parse" 
                                                                      code:0  
                                                                  userInfo:[NSDictionary dictionaryWithObject:@"Header too short" forKey:@"error"]];
                        
                        if (error != NULL) {
                            (*error) = myError; 
                        }
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
                        
                        if (error != NULL) {
                            (*error) = myError;                        
                        }
                        return;
                    }
                    
                    NSError* sectionError = NULL;
                    
                    while(offset < [data length] && CFArrayGetCount(points) < length) {
                        offset = [OTMAPI parseSection:data offset:offset points:points error:&sectionError];
                        
                        if (sectionError != NULL) {
                            if (error != NULL) {
                                (*error) = sectionError;
                            }
                            
                            return;
                        }
                    }
                    
                    callback(points);
                    
                    for(int i=0;i<CFArrayGetCount(points);i++) {
                        free((void *)CFArrayGetValueAtIndex(points, i));
                    }
                    
                    CFRelease(points);
                    points = NULL;
                }];        
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
    [request get:@"login" withUser:user params:nil callback:[OTMAPI jsonCallback:callback]];
}

@end
