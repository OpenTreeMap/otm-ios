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
#import "AZJSONResponse.h"
#import "AZDataResponse.h"

@implementation OTMAPI

@synthesize request;

-(void)getPlotsNearLatitude:(double)lat longitude:(double)lon callback:(AZJSONCallback)callback {
    [self.request get:@"locations/:lat,:lon/plots" 
               params:[NSDictionary dictionaryWithObjectsAndKeys:
                       [NSString stringWithFormat:@"%f", lat], @"lat",
                       [NSString stringWithFormat:@"%f", lon], @"lon", nil]
             callback:^(id req) { 
                 if (callback) {
                     callback([(AZJSONResponse*)[req response] json]);
                 }
             }];
}

-(void)getImageForTree:(int)plotid photoId:(int)photoid callback:(AZImageCallback)callback {
    [self.request getRaw:@"plots/:plot/tree/photo/:photo" 
                  params:[NSDictionary dictionaryWithObjectsAndKeys:
                          [NSString stringWithFormat:@"%d", plotid], @"plot",
                          [NSString stringWithFormat:@"%d", photoid], @"photo", nil]
                    mime:@"image/jpeg"
                callback:^(id req) { 
                    if (callback) {
                        callback([UIImage imageWithData:[(AZDataResponse*)[req response] data]]);
                    }
                }];    
}

@end
