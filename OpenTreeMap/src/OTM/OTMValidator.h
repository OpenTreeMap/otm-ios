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
 * init with an array of validation blocks of type OTMValidatorValidation
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
 * Execute validations. If validation fails, show an alert about it.
 *
 * @param controller the controller to validate
 *
 * @return YES if validation is successful, NO otherwise
 */
-(BOOL)executeValidationsAndAlertWithViewController:(UIViewController *)controller;

/**
 * Validate that v1 OR v1 returns a valid result
 *
 * Note that the error from v1 will never be shown (if both are bad then
 * the v2 error will be shown)
 */
+(OTMValidatorValidation)validation:(OTMValidatorValidation)v1 or:(OTMValidatorValidation)v2 display:(NSString *)display;

@property (nonatomic,strong) NSArray *validations;

@end

/**
 * Helper methods for generating text field validations
 */
@interface OTMTextFieldValidator : NSObject

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


@end
