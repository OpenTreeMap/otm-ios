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

@property (nonatomic,copy) NSString* baseURL;
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


/**
 * Perform DELETE HTTP request
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
-(void)delete:(NSString*)url withUser:(AZUser *)user params:(NSDictionary*)params callback:(ASIRequestCallback)callback;

@end
