//
//  OTMAPICall.h
//  OpenTreeMap
//
//  Created by Adam Hinz on 2/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
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
