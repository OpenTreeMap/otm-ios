//
//  OTMAPICall.m
//  OpenTreeMap
//
//  Created by Adam Hinz on 2/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OTMAPICall.h"
#import "OTMJSONResponse.h"

@interface OTMAPICall(private)

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

@end

/**
 * Dummy delegate to allow us to pass blocks to 320 Network Requests
 */
@interface OTMAPICallDelegate : NSObject {
    TTRequestCallback callback;
}

@property (nonatomic,copy) TTRequestCallback callback;

+(id)delegateWithBlock:(TTRequestCallback)callback;


@end

@implementation OTMAPICallDelegate

@synthesize callback;

+(id)delegateWithBlock:(TTRequestCallback)callback {
    OTMAPICallDelegate* delegate = [[OTMAPICallDelegate alloc] init];
    delegate.callback = callback;
    
    return delegate;
}

-(void)requestDidFinishLoad:(TTURLRequest *)request {
    if (callback) {
        callback(request, [(OTMJSONResponse*)[request response] json]);
    }
    
    CFBridgingRelease((__bridge void*)self);
}

@end

@implementation OTMAPICall

+(void)executeAPICall:(NSString*)url params:(NSDictionary*)params callback:(TTRequestCallback)callback {
    NSDictionary* nonUrlParams;
    url = [OTMAPICall replacePlaceholdersInURL:url withParams:params remainingParams:&nonUrlParams];
    
    NSString* base = @"http://207.245.89.246/v1.2/api/v0.1";
    NSMutableString* query = [NSMutableString stringWithFormat:@"%@/%@?", base, url];
    
    [nonUrlParams enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL* stop) {
        [query appendFormat:@"%@=%@&", key, obj];
    }];
    
    NSString* queryURL = [query substringToIndex:[query length] - 1];
    
    OTMAPICallDelegate* delegate = [OTMAPICallDelegate delegateWithBlock:callback];
    TTURLRequest *request = [TTURLRequest requestWithURL:queryURL delegate:delegate];
    
    request.response = [[OTMJSONResponse alloc] init];
    
    // The TTURLRequest does not keep strong references to the delegate
    // so we retain it here
    CFBridgingRetain(delegate);
    
    // The request must be sent on the main thread in order to correctly return
    [request performSelectorOnMainThread:@selector(send) withObject:nil waitUntilDone:NO];
}

@end

@implementation OTMAPICall(private)

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

@end