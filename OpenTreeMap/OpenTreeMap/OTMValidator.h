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

/**
 * A validation takes a view controller and then returns
 * either "nil" to represent a success or an error string
 * in the case of failure
 */
typedef NSString *(^OTMValidatorValidation)(UIViewController *vc);

/**
 * A validator manages validations and provides a couple of useful methods
 * for running them on view controllers
 */
@interface OTMValidator : NSObject

/**
 * init with an array of validation blocks
 */
-(id)initWithValidations:(NSArray *)validations;

/**
 * Execute validations
 *
 * @param controller the controller to validate
 * @param (out param) the validation error
 *
 * @return YES if validation is successful, NO otherwise
 */
-(BOOL)executeValidationsWithViewController:(UIViewController *)controller error:(NSString **)error;

/**
 * Execute validations. If validation fails, so an alert about it.
 *
 * @param controller the controller to validate
 *
 * @return YES if validation is successful, NO otherwise
 */
-(BOOL)executeValidationsAndAlertWithViewController:(UIViewController *)controller;

/**
 * Create a validation for the minimum length of the field
 */
+(OTMValidatorValidation)minLengthValidation:(NSString *)field display:(NSString *)display minLength:(int)len;

/**
 * Validate that a field is not blank
 */
+(OTMValidatorValidation)notBlankValidation:(NSString *)field display:(NSString *)display;

/**
 * Validate a specific length
 */
+(OTMValidatorValidation)lengthValidation:(NSString *)field display:(NSString *)display length:(int)len;

/**
 * Validate that a field is not blank
 *
 * Note that this is particularly (only?) useful when paried with the "or" operator
 * below.
 *
 * For instance, [OTMValidator validation:[OTMValidator notBlank:...]
 *                                     or:[OTMValidator sizeIs:5 ...]]
 * Would match empty fields or fields with five characters
 */
+(OTMValidatorValidation)isBlankValidation:(NSString *)field display:(NSString *)display;

/**
 * Validate that the given field is an email address
 */
+(OTMValidatorValidation)emailValidation:(NSString *)field display:(NSString *)display;

/**
 * Validate that v1 OR v1 returns a valid result
 *
 * Note that the error from v1 will never be shown (if both are bad then
 * the v2 error will be shown)
 */
+(OTMValidatorValidation)validation:(OTMValidatorValidation)v1 or:(OTMValidatorValidation)v2 display:(NSString *)display;

@property (nonatomic,strong) NSArray *validations;

@end
