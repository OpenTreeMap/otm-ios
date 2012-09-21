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
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "OTMFilterListViewController.h"
#import "AZHttpRequest.h"
#import "OTMUser.h"

typedef enum {
    kOTMAPILoginResponseInvalidUsernameOrPassword,
    kOTMAPILoginResponseOK,
    kOTMAPILoginResponseError,
    kOTMAPILoginDuplicateUsername
} OTMAPILoginResponse;

typedef void(^AZGenericCallback)(id obj, NSError* error);
typedef void(^AZJSONCallback)(id json, NSError* error);
typedef void(^AZImageCallback)(UIImage* image, NSError* error);
typedef void(^AZUserCallback)(OTMUser* user, OTMAPILoginResponse status);

/**
 * OTM API Provides a functional wrapper around the OpenTreeMap API
 *
 * This is a singleton object - grab it from the OTMEnironment
 */
@interface OTMAPI : NSObject {
    NSDictionary *species;
    NSOperationQueue *geocodeQueue;
    CLRegion *geocodeRegion;
    CLGeocoder *geocoder;
}

/**
 * Object used for doing our http requests
 */
@property (nonatomic,strong) AZHttpRequest* tileRequest;
@property (nonatomic,strong) AZHttpRequest* request;

+(ASIRequestCallback)liftResponse:(AZGenericCallback)callback;

/**
 * Get species list
 */
-(void)getSpeciesListWithCallback:(AZJSONCallback)callback;

/**
 * Save the given plot
 *
 * If there is no <id> element, create a new plot
 * If there is a <tree> element, create or update the inner tree
 */
-(void)savePlot:(NSDictionary *)plot withUser:(OTMUser *)user callback:(AZJSONCallback)callback;

/**
 * Get the plot nearested to (lat,lon)
 *
 * @param lat,lon latitude and longitude of the point of intererest
 * @param the user making the request
 * @param macResults maximum number of trees to return
 * @param callback receives a NSArray of NSDictionaries representing plots
 */
-(void)getPlotsNearLatitude:(double)lat longitude:(double)lon user:(OTMUser *)user maxResults:(NSUInteger)max filters:(OTMFilters *)filters callback:(AZJSONCallback)callback;
-(void)getPlotsNearLatitude:(double)lat longitude:(double)lon user:(OTMUser *)user maxResults:(NSUInteger)maxResults callback:(AZJSONCallback)callback;
-(void)getPlotsNearLatitude:(double)lat longitude:(double)lon user:(OTMUser *)user callback:(AZJSONCallback)callback;
-(void)getPlotsNearLatitude:(double)lat longitude:(double)lon user:(OTMUser *)user filters:(OTMFilters *)filters callback:(AZJSONCallback)callback;
-(void)getPlotsNearLatitude:(double)lat longitude:(double)lon user:(OTMUser *)user maxResults:(NSUInteger)max filters:(OTMFilters *)filters distance:(double)distance callback:(AZJSONCallback)callback;
 
/**
 * Request an image for a given tree/plot
 *
 * @param plotid the plot's id
 * @param imageid the image's id
 */
-(void)getImageForTree:(int)plotid photoId:(int)photoid callback:(AZImageCallback)callback;

/**
 * Attempt to log the given user in. If successful user.loggedIn will return
 * true
 *
 * @param user the user to login
 * @param callback the callback to call when execution has finished
 */
-(void)logUserIn:(OTMUser*)user callback:(AZUserCallback)callback;

/**
 * Retrieve a dictionary of user profile details.
 *
 * @param user the user for whom details are being fetches
 * @param callback the callback to call when execution has finished
 */
-(void)getProfileForUser:(OTMUser*)user callback:(AZJSONCallback)callback;

/**
 * Reset the password on an account
 *
 * @param email the email attached to the user that is to be reset
 */
-(void)resetPasswordForEmail:(NSString*)email callback:(AZJSONCallback)callback;

/**
 * Create a new user and log them in
 *
 * @param user the user to create
 * @param callback completion callback
 */
-(void)createUser:(OTMUser *)user callback:(AZUserCallback)callback;

/**
 * Change a user's password
 *
 * @param user user's password to change
 * @param newPass the new password
 */
-(void)changePasswordForUser:(OTMUser *)user to:(NSString *)newPass callback:(AZUserCallback)callback;

/**
 * The a user's profile picture
 */
-(void)setProfilePhoto:(OTMUser *)user callback:(AZJSONCallback)callback;

/**
 * Set tree photo
 */
-(void)setPhoto:(UIImage *)image onPlotWithID:(NSUInteger)pId withUser:(OTMUser *)user callback:(AZJSONCallback)cb;

/**
 * Get recent edit (reputation) actions for a user
 *
 * @param user the user to get actions from
 * @param offset collection offset
 * @param length number of results to return
 * @param callback the callback
 */
-(void)getRecentActionsForUser:(OTMUser *)user offset:(NSUInteger)offset length:(NSUInteger)length callback:(AZJSONCallback)callback;
-(void)getRecentActionsForUser:(OTMUser *)user offset:(NSUInteger)offset callback:(AZJSONCallback)callback;
-(void)getRecentActionsForUser:(OTMUser *)user callback:(AZJSONCallback)callback;

/**
 * Find the coordinates of the specified address. Expects the API to return
 * an array of objects with the following schema:
 *
 *  {
 *    "match_addr": "1234 SAMPLE ST, ANYTOWN, US",
 *    "x": -75.1583244,
 *    "y": 39.9583742,
 *    "score": 92, // similarity to the specified address. 1 to 100
 *    "locator": "parcel" // detail on the method used to find the location
 *    "geoservice": "Bing" // The geocoding provider that returned the result
 *    "wkid": 4326 // The spatial reference of the x and y coordinates
 *  }
 *
 * If there are mutiple matches, the array will be sorted by the "score" property
 * of each object.
 *
 * @param address the address to be geocoded
 * @param callback method that will be executed and passed the geocoder response
 */
-(void)geocodeAddress:(NSString *)address callback:(AZJSONCallback)callback;


/**
 * Get the address details for a map coordinate
 * @param coordinate the coordinate for which address details should be retrieved
 * @param callback method that will be executed and passed the reverse geocoder response
 */
-(void)reverseGeocodeCoordinate:(CLLocationCoordinate2D)coordinate callback:(AZGenericCallback)callback;

/**
 * Create a new plot and create a new tree in that plot if tree details are included
 * in the detail dictionary.
 * @param dictionary with plot, tree, and geometry information
 */
-(void)addPlotWithOptionalTree:(NSDictionary *)details user:(OTMUser *)user callback:(AZJSONCallback)callback;

/**
 * Update the plot and its current tree
 * @param details dictionary with plot, tree, and geometry information
 * @param user the authenticated user who is making the edit
 * @param callback block to be executed when the request is complete or an error occurs
 */
-(void)updatePlotAndTree:(NSDictionary *)details user:(OTMUser *)user callback:(AZJSONCallback)callback;

/**
 * Approve a pending edit and reject all other pending edits for the same field
 * @param pendingEditId the id of the pending edit to be approved
 * @param user the authenticated user who is approving the pending edit
 * @param callback block to be executed when the request is complete or an error occurs
 */
-(void)approvePendingEdit:(NSInteger)pendingEditId user:(OTMUser *)user callback:(AZJSONCallback)callback;

/**
 * Reject a pending edit
 * @param pendingEditId the id of the pending edit to be rejected
 * @param user the authenticated user who is approving the pending edit
 * @param callback block to be executed when the request is complete or an error occurs
 */
-(void)rejectPendingEdit:(NSInteger)pendingEditId user:(OTMUser *)user callback:(AZJSONCallback)callback;

/**
 * Delete the current tree from a plot
 * @param plotId the ID of a plot from which the tree should be removed
 * @param user the authenticated user who is deleting the tree
 * @param callback block to be executed when the request is complete or an error occurs
 */
-(void)deleteTreeFromPlot:(NSInteger)plotId user:(OTMUser *)user callback:(AZJSONCallback)callback;

/**
 * Delete a plot
 * @param plotId the ID of a plot to be deleted
 * @param user the authenticated user who is deleting the plot
 * @param callback block to be executed when the request is complete or an error occurs
 */
-(void)deletePlot:(NSInteger)plotId user:(OTMUser *)user callback:(AZJSONCallback)callback;

@end
