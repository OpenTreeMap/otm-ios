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
-(NSString*)replacePlaceholdersInURL:(NSString*)url withParams:(NSDictionary*)params remainingParams:(NSDictionary**)rparams;

/**
 * Transform the query string by replacing placeholders with the form ":key" based
 * on the params hash and a query string (?key=value) for the rest
 *
 * @param url the url to transform
 * @param params the paramater dictionary
 *
 * @returns url with params and query string
 */
-(NSString*)generateURL:(NSString*)url withParams:(NSDictionary*)params;

/**
 * Build a basic TTURLRequest and pass it to the config block to be
 * configured and then run and execute it
 *
 * @param url the url to request
 * @param callback the block to call when the request is done
 * @param config config block
 */
-(void)executeRequestWithURL:(NSString*)url callback:(ASIRequestCallback)callback config:(ASIRequestConfig)config;
-(void)executeRequestWithURL:(NSString*)url callback:(ASIRequestCallback)callback;
-(void)executeAuthorizedRequestWithURL:(NSString*)url username:(NSString*)username password:(NSString*)password callback:(ASIRequestCallback)callback config:(ASIRequestConfig)config; 
-(void)executeAuthorizedRequestWithURL:(NSString*)url username:(NSString*)username password:(NSString*)password callback:(ASIRequestCallback)callback;

/**
 * Log the details of an HTTP request
 * @param request the ASIHTTPRequest to be logged
 *
 */
-(void)logHttpRequest:(ASIHTTPRequest *)request;

@end

@implementation AZHttpRequest

@synthesize baseURL, headers, queue;

-(id)initWithURL:(NSString*)base {
    if (self = [[AZHttpRequest alloc] init]) {
        baseURL = [base copy];
        queue = [[NSOperationQueue alloc] init];
        queue.maxConcurrentOperationCount = 1;
    }
    
    return self;
}

-(void)get:(NSString*)url params:(NSDictionary*)params callback:(ASIRequestCallback)callback {                          
    [self executeRequestWithURL:[self generateURL:url withParams:params] 
                       callback:callback];
}

-(void)get:(NSString*)url withUser:(AZUser*)user params:(NSDictionary*)params callback:(ASIRequestCallback)callback {
    [self executeAuthorizedRequestWithURL:[self generateURL:url withParams:params]
                                 username:[user username]
                                 password:[user password]
                                 callback:callback];
}

-(void)getRaw:(NSString*)url params:(NSDictionary*)params mime:(NSString*)mime callback:(ASIRequestCallback)callback {
    [self executeRequestWithURL:[self generateURL:url withParams:params] 
                       callback:callback
                         config:^(ASIHTTPRequest* r) {
                             [r addRequestHeader:@"Accept" value:mime];
                         }];
}

-(void)post:(NSString*)url withUser:(AZUser *)user params:(NSDictionary*)params data:(NSData*)data callback:(ASIRequestCallback)callback {
    [self executeAuthorizedRequestWithURL:[self generateURL:url withParams:params] 
                                 username:user.username
                                 password:user.password
                                 callback:callback
                                   config:^(ASIHTTPRequest* r) {
                                       [r setPostBody:[NSMutableData dataWithData:data]];
                                       [r setRequestMethod:@"POST"];
                                       [r addRequestHeader:@"Content-Type"
                                                     value:@"application/json"];
                                   }];
}

-(void)post:(NSString*)url params:(NSDictionary*)params data:(NSData*)data callback:(ASIRequestCallback)callback {
    [self executeRequestWithURL:[self generateURL:url withParams:params] 
                       callback:callback
                         config:^(ASIHTTPRequest* r) {
                             [r setPostBody:[NSMutableData dataWithData:data]];
                             [r setRequestMethod:@"POST"];
                             [r addRequestHeader:@"Content-Type"
                                           value:@"application/json"];
                         }];
}

-(void)put:(NSString*)url withUser:(AZUser *)user params:(NSDictionary*)params data:(NSData*)data callback:(ASIRequestCallback)callback {
    [self executeAuthorizedRequestWithURL:[self generateURL:url withParams:params] 
                                 username:user.username
                                 password:user.password
                                 callback:callback
                                   config:^(ASIHTTPRequest* r) {
                                       [r setPostBody:[NSMutableData dataWithData:data]];
                                       [r setRequestMethod:@"PUT"];
                                       [r addRequestHeader:@"Content-Type"
                                                     value:@"application/json"];
                                   }];
}

-(void)put:(NSString*)url params:(NSDictionary*)params data:(NSData*)data callback:(ASIRequestCallback)callback {
    [self executeRequestWithURL:[self generateURL:url withParams:params] 
                       callback:callback
                         config:^(ASIHTTPRequest* r) {
                             [r setPostBody:[NSMutableData dataWithData:data]];
                             [r setRequestMethod:@"PUT"];
                             [r addRequestHeader:@"Content-Type"
                                           value:@"application/json"];
                         }];
}

@end

@implementation AZHttpRequest(private)

-(NSString*)replacePlaceholdersInURL:(NSString*)url withParams:(NSDictionary*)params remainingParams:(NSDictionary**)rparams {
    NSMutableString* murl = [NSMutableString stringWithString:url];
    NSMutableDictionary* unusedParams = [NSMutableDictionary dictionary];
    
    [params enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString *strObj = [NSString stringWithFormat:@"%@",obj];
        int reps = [murl replaceOccurrencesOfString:[NSString stringWithFormat:@":%@", key]
                                         withString:strObj
                                            options:NSCaseInsensitiveSearch
                                              range:NSMakeRange(0, [murl length])];
        
        if (reps == 0) {
            [unusedParams setObject:obj forKey:key];
        }
    }];
    
    *rparams = unusedParams;
    
    return murl;
}   

-(NSString*)generateURL:(NSString*)url withParams:(NSDictionary*)params {
    NSDictionary* nonUrlParams;
    url = [self replacePlaceholdersInURL:url withParams:params remainingParams:&nonUrlParams];
    
    NSMutableString* query = [NSMutableString stringWithFormat:@"%@?", url];
    
    [nonUrlParams enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL* stop) {
        [query appendFormat:@"%@=%@&", key, obj];
    }];
    
    return [query substringToIndex:[query length] - 1];
}

-(void)executeRequestWithURL:(NSString*)url callback:(ASIRequestCallback)callback {
    [self executeRequestWithURL:url callback:callback config:^(id a) {}];
}

-(void)executeAuthorizedRequestWithURL:(NSString*)url username:(NSString*)username password:(NSString*)password callback:(ASIRequestCallback)callback config:(ASIRequestCallback)config {
    [self executeRequestWithURL:url callback:callback config:^(ASIHTTPRequest* req) {
        [req addBasicAuthenticationHeaderWithUsername:username
                                          andPassword:password];
        
        req.shouldPresentAuthenticationDialog = NO;
        req.shouldPresentCredentialsBeforeChallenge = YES;
                
        if (config != nil) {
            config(req);
        }
    }];
}

-(void)executeAuthorizedRequestWithURL:(NSString*)url username:(NSString*)username password:(NSString*)password callback:(ASIRequestCallback)callback {
    [self executeAuthorizedRequestWithURL:url username:username password:password callback:callback config:nil];
}


-(void)executeRequestWithURL:(NSString*)urlsfx callback:(ASIRequestCallback)callback config:(ASIRequestConfig)config {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",self.baseURL,urlsfx]];
    
    __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    __weak ASIHTTPRequest *blockRequest = request;
    [request setCompletionBlock:^{
        if (callback != nil) {
            callback(blockRequest);
        }
    }];
    [request setFailedBlock:^{
        if (callback != nil) {
            callback(blockRequest);
        }
    }];

    [request addRequestHeader:@"Accept" value:@"application/json"];
    
    if (self.headers) {
        [self.headers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL* stop) {
            [request addRequestHeader:key value:obj];
        }];
    }

    if (config != nil) {
        config(request);
    }
    
    [self logHttpRequest:request];

    [[self queue] addOperation:request];
}

-(void)logHttpRequest:(ASIHTTPRequest *)request {
    if ([request postBody]) {
        NSString *postBodyAsString;
        if ([[request postBody] length] <= 1024) {
            postBodyAsString = [[NSString alloc] initWithData:[request postBody] encoding:NSUTF8StringEncoding];
        } else {
            postBodyAsString = @"<body larger than 1024 bytes>";
        }
        NSLog(@"%@ %@\n%@", [request requestMethod], [request url], postBodyAsString);
    } else {
        NSLog(@"%@ %@", [request requestMethod], [request url]);
    }
}

@end