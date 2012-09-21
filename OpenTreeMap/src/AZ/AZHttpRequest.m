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

@synthesize baseURL, headers, queue, synchronous;

-(id)initWithURL:(NSString*)base {
    if (self = [[AZHttpRequest alloc] init]) {
        baseURL = [base copy];
        queue = [[NSOperationQueue alloc] init];
        queue.maxConcurrentOperationCount = 2;
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

-(void)post:(NSString*)url withUser:(AZUser *)user params:(NSDictionary*)params data:(NSData*)data contentType:(NSString *)contentType callback:(ASIRequestCallback)callback {
    [self executeAuthorizedRequestWithURL:[self generateURL:url withParams:params] 
                                 username:user.username
                                 password:user.password
                                 callback:callback
                                   config:^(ASIHTTPRequest* r) {
                                       [r setPostBody:[NSMutableData dataWithData:data]];
                                       [r setRequestMethod:@"POST"];
                                       [r addRequestHeader:@"Content-Type"
                                                     value:contentType];
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

-(void)delete:(NSString*)url withUser:(AZUser *)user params:(NSDictionary*)params callback:(ASIRequestCallback)callback {
    [self executeAuthorizedRequestWithURL:[self generateURL:url withParams:params]
                                 username:user.username
                                 password:user.password
                                 callback:callback
                                   config:^(ASIHTTPRequest* r) {
                                       [r setRequestMethod:@"DELETE"];
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

    #ifdef DEBUG
    [self logHttpRequest:request];
    #endif

    if (synchronous) {
        [request startSynchronous];
    } else {
        [[self queue] addOperation:request];
    }
}

-(void)logHttpRequest:(ASIHTTPRequest *)request {
    if ([request postBody]) {
        NSString *postBodyAsString;
        if ([[request postBody] length] <= 1024) {
            postBodyAsString = [[NSString alloc] initWithData:[request postBody] encoding:NSUTF8StringEncoding];
        } else {
            postBodyAsString = @"<body larger than 1024 bytes>";
        }
        NSLogD(@"%@ %@\n%@", [request requestMethod], [request url], postBodyAsString);
    } else {
        NSLogD(@"%@ %@", [request requestMethod], [request url]);
    }
}

@end
