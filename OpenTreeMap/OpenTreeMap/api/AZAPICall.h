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

#import <Foundation/Foundation.h>
#import "Three20Network/Three20Network.h"

/**
 * Callback for receiving JSON via a TTURLRequest
 */
typedef void(^TTRequestCallback)(TTURLRequest* req,id json);

/**
 * Static namespace for convenience functions for calling OTM APIs
 */
@interface OTMAPICall : NSObject

/**
 * Perform an API call
 * Note that strings of the form: ":key" are replaced with the values in the
 * params dictionary (so url "plots/:id/trees", params { "id" => 5, "size" => 10 }, would
 * end up with a url of: "plots/5/trees?size=10")
 *
 * @param url the endpoint to hit. The prefix will be added automatically so this 
 *            is something like: "plots/:id/"
 * @param params dictionary of key/value parameter pairs
 * @param callback called on success
 *
 */
+(void)executeAPICall:(NSString*)url params:(NSDictionary*)params callback:(TTRequestCallback)callback;

@end
