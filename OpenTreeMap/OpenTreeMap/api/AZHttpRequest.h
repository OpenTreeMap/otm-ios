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
#import "ASIHTTPRequest.h"
#import "AZUser.h"

/**
 * Callback for receiving JSON via a TTURLRequest
 */
typedef void(^ASIRequestCallback)(ASIHTTPRequest* req);

/**
 * Config block callback
 */
typedef void(^ASIRequestConfig)(ASIHTTPRequest* req);

/**
 * Convenience functions for calling OTM APIs
 */
@interface AZHttpRequest : NSObject

@property (nonatomic,copy,readonly) NSString* baseURL;
@property (nonatomic,strong) NSDictionary* headers;
@property (nonatomic,readonly) NSOperationQueue *queue;
@property (nonatomic,assign) BOOL synchronous;

/**
 * Initialize with a base url
 *
 * @param base the url prefixed onto all of the calls
 */
-(id)initWithURL:(NSString*)base;

/**
 * Perform an API call
 * Note that strings of the form: ":key" are replaced with the values in the
 * params dictionary (so url "plots/:id/trees", params { "id" => 5, "size" => 10 }, would
 * end up with a url of: "plots/5/trees?size=10")
 *
 * This method assumes that the data coming back is json
 *
 * @param url the endpoint to hit. The prefix will be added automatically so this 
 *            is something like: "plots/:id/"
 * @param params dictionary of key/value parameter pairs
 * @param callback called on success
 *
 */
-(void)get:(NSString*)url params:(NSDictionary*)params callback:(ASIRequestCallback)callback;

/**
 * Perform an API call
 * Note that strings of the form: ":key" are replaced with the values in the
 * params dictionary (so url "plots/:id/trees", params { "id" => 5, "size" => 10 }, would
 * end up with a url of: "plots/5/trees?size=10")
 *
 * This method assumes that the data coming back is json
 *
 * @param url the endpoint to hit. The prefix will be added automatically so this 
 *            is something like: "plots/:id/"
 * @param user the user to use for authorization
 * @param params dictionary of key/value parameter pairs
 * @param callback called on success
 *
 */
-(void)get:(NSString*)url withUser:(AZUser*)user params:(NSDictionary*)params callback:(ASIRequestCallback)callback;

/**
 * Perform an API call
 * Note that strings of the form: ":key" are replaced with the values in the
 * params dictionary (so url "plots/:id/trees", params { "id" => 5, "size" => 10 }, would
 * end up with a url of: "plots/5/trees?size=10")
 *
 * This method returns raw byte data to the response handler
 *
 * @param url the endpoint to hit. The prefix will be added automatically so this 
 *            is something like: "plots/:id/"
 * @param params dictionary of key/value parameter pairs
 * @param mime the mime type to pass as the accept header
 * @param callback called on success
 *
 */
-(void)getRaw:(NSString*)url params:(NSDictionary*)params mime:(NSString*)mime callback:(ASIRequestCallback)callback;

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
-(void)post:(NSString*)url params:(NSDictionary*)params data:(NSData*)data callback:(ASIRequestCallback)callback;

/**
 * Perform an API call
 * Note that strings of the form: ":key" are replaced with the values in the
 * params dictionary (so url "plots/:id/trees", params { "id" => 5, "size" => 10 }, would
 * end up with a url of: "plots/5/trees?size=10")
 *
 * @param url the endpoint to hit. The prefix will be added automatically so this 
 *            is something like: "plots/:id/"
 * @param user the user to authenticate with
 * @param params dictionary of key/value parameter pairs
 * @param callback called on success
 *
 */
-(void)post:(NSString*)url withUser:(AZUser *)user params:(NSDictionary*)params data:(NSData*)data contentType:(NSString *)contentType callback:(ASIRequestCallback)callback;

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
-(void)put:(NSString*)url params:(NSDictionary*)params data:(NSData*)data callback:(ASIRequestCallback)callback;

/**
 * Perform an API call
 * Note that strings of the form: ":key" are replaced with the values in the
 * params dictionary (so url "plots/:id/trees", params { "id" => 5, "size" => 10 }, would
 * end up with a url of: "plots/5/trees?size=10")
 *
 * @param url the endpoint to hit. The prefix will be added automatically so this 
 *            is something like: "plots/:id/"
 * @param user the user to authenticate
 * @param params dictionary of key/value parameter pairs
 * @param callback called on success
 *
 */
-(void)put:(NSString*)url withUser:(AZUser *)user params:(NSDictionary*)params data:(NSData*)data callback:(ASIRequestCallback)callback;


@end
