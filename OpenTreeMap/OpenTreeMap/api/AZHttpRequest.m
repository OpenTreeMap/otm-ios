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

#import "AZHttpRequest.h"
#import "AZJSONResponse.h"

@interface AZHttpRequest(private)

/**
 * Transform the query string by replacing placeholders with the form ":key" based
 * on the params hash
 *
 * @param url the url to transform
 * @param params the paramater dictionary
 * @param rparams (out param) returns dictionary of items that were not used
 *
 * @returns URL with keys replaced
 */
+(NSString*)replacePlaceholdersInURL:(NSString*)url withParams:(NSDictionary*)params remainingParams:(NSDictionary**)rparams;

/**
 * Transform the query string by replacing placeholders with the form ":key" based
 * on the params hash and a query string (?key=value) for the rest
 *
 * @param url the url to transform
 * @param params the paramater dictionary
 *
 * @returns url with params and query string
 */
+(NSString*)generateURL:(NSString*)url withParams:(NSDictionary*)params;

/**
 * Build a basic TTURLRequest and pass it to the config block to be
 * configured and then run and execute it
 *
 * @param url the url to request
 * @param callback the block to call when the request is done
 * @param config config block
 */
+(void)executeRequestWithURL:(NSString*)url callback:(TTRequestCallback)callback config:(TTRequestConfig)config;
+(void)executeRequestWithURL:(NSString*)url callback:(TTRequestCallback)callback;

@end

/**
 * Dummy delegate to allow us to pass blocks to 320 Network Requests
 */
@interface AZAPICallDelegate : NSObject {
    TTRequestCallback callback;
}

@property (nonatomic,copy) TTRequestCallback callback;

+(id)delegateWithBlock:(TTRequestCallback)callback;


@end

@implementation AZAPICallDelegate

@synthesize callback;

+(id)delegateWithBlock:(TTRequestCallback)callback {
    AZAPICallDelegate* delegate = [[AZAPICallDelegate alloc] init];
    delegate.callback = callback;
    
    return delegate;
}

-(void)requestDidFinishLoad:(TTURLRequest *)request {
    if (callback) {
        callback(request, [(AZJSONResponse*)[request response] json]);
    }
    
    CFBridgingRelease((__bridge void*)self);
}

@end

@implementation AZHttpRequest

+(void)get:(NSString*)url params:(NSDictionary*)params callback:(TTRequestCallback)callback {                          
    [AZHttpRequest executeRequestWithURL:[AZHttpRequest generateURL:url withParams:params] 
                                callback:callback];
}

+(void)post:(NSString*)url params:(NSDictionary*)params data:(NSData*)data callback:(TTRequestCallback)callback {
    [AZHttpRequest executeRequestWithURL:[AZHttpRequest generateURL:url withParams:params] 
                                callback:callback
                                  config:^(TTURLRequest* r) {
                                      r.httpBody = data;
                                      r.httpMethod = @"POST";
                                      r.contentType = @"application/json";
                                  }];
}

+(void)put:(NSString*)url params:(NSDictionary*)params data:(NSData*)data callback:(TTRequestCallback)callback {
    [AZHttpRequest executeRequestWithURL:[AZHttpRequest generateURL:url withParams:params] 
                                callback:callback
                                  config:^(TTURLRequest* r) {
                                      r.httpBody = data;
                                      r.httpMethod = @"PUT";
                                      r.contentType = @"application/json";
                                  }];
}

@end

@implementation AZHttpRequest(private)

+(NSString*)replacePlaceholdersInURL:(NSString*)url withParams:(NSDictionary*)params remainingParams:(NSDictionary**)rparams {
    NSMutableString* murl = [NSMutableString stringWithString:url];
    NSMutableDictionary* unusedParams = [NSMutableDictionary dictionary];
    
    [params enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        int reps = [murl replaceOccurrencesOfString:[NSString stringWithFormat:@":%@", key]
                                         withString:obj
                                            options:NSCaseInsensitiveSearch
                                              range:NSMakeRange(0, [murl length])];
        
        if (reps == 0) {
            [unusedParams setObject:obj forKey:key];
        }
    }];
    
    *rparams = unusedParams;
    
    return murl;
}

+(NSString*)generateURL:(NSString*)url withParams:(NSDictionary*)params {
    NSDictionary* nonUrlParams;
    url = [AZHttpRequest replacePlaceholdersInURL:url withParams:params remainingParams:&nonUrlParams];
    
    NSMutableString* query = [NSMutableString stringWithFormat:@"%@?", url];
    
    [nonUrlParams enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL* stop) {
        [query appendFormat:@"%@=%@&", key, obj];
    }];
    
    return [query substringToIndex:[query length] - 1];
}

+(void)executeRequestWithURL:(NSString*)url callback:(TTRequestCallback)callback {
    [AZHttpRequest executeRequestWithURL:url callback:callback config:^(id a) {}];
}

+(void)executeRequestWithURL:(NSString*)url callback:(TTRequestCallback)callback config:(TTRequestConfig)config {
    AZAPICallDelegate* delegate = [AZAPICallDelegate delegateWithBlock:callback];
    TTURLRequest *request = [TTURLRequest requestWithURL:url delegate:delegate];
    
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    request.response = [[AZJSONResponse alloc] init];
    
    config(request);
    
    // The TTURLRequest does not keep strong references to the delegate
    // so we retain it here
    CFBridgingRetain(request.response);
    
    // The request must be sent on the main thread in order to correctly return
    [request performSelectorOnMainThread:@selector(send) withObject:nil waitUntilDone:NO];
}

@end