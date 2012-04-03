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
#import "AZHttpRequest.h"
#import "OTMUser.h"

typedef enum {
    kOTMAPILoginResponseInvalidUsernameOrPassword,
    kOTMAPILoginResponseOK,
    kOTMAPILoginResponseError,
    kOTMAPILoginDuplicateUsername
} OTMAPILoginResponse;

typedef void(^AZJSONCallback)(id json, NSError* error);
typedef void(^AZImageCallback)(UIImage* image, NSError* error);
typedef void(^AZUserCallback)(OTMUser* user, OTMAPILoginResponse status);

typedef struct { uint32_t xoffset; uint32_t yoffset; uint32_t style; } OTMPoint;

typedef void(^AZPointDataCallback)(CFArrayRef, NSError* error);

/**
 * OTM API Provides a functional wrapper around the OpenTreeMap API
 *
 * This is a singleton object - grab it from the OTMEnironment
 */
@interface OTMAPI : NSObject

/**
 * Object used for doing our http requests
 */
@property (nonatomic,strong) AZHttpRequest* request;

/**
 * Get the plot nearested to (lat,lon)
 *
 * @param lat,lon latitude and longitude of the point of intererest
 * @param callback receives a NSArray of NSDictionaries representing plots
 */
-(void)getPlotsNearLatitude:(double)lat longitude:(double)lon callback:(AZJSONCallback)callback;

/**
 * Request an image for a given tree/plot
 *
 * @param plotid the plot's id
 * @param imageid the image's id
 */
-(void)getImageForTree:(int)plotid photoId:(int)photoid callback:(AZImageCallback)callback;

/**
 * Get point offsets for a given tile
 * To keep this method performant it uses a custom callback
 *
 * @param region WSG84 Region
 * @param callback the callback we get when we are done
 * @param error error pointer
 */
-(void)getPointOffsetsInTile:(MKCoordinateRegion)region callback:(AZPointDataCallback)callback;

/**
 * Attempt to log the given user in. If successful user.loggedIn will return
 * true
 *
 * @param user the user to login
 * @param callback the callback to call when execution has finished
 */
-(void)logUserIn:(OTMUser*)user callback:(AZUserCallback)callback;

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


@end
