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

#import "OTMValidator.h"

@implementation OTMValidator

@synthesize validations;

+(OTMValidatorValidation)validation:(OTMValidatorValidation)v1 or:(OTMValidatorValidation)v2 display:(NSString *)display {
    return [^(UIViewController *vc) {
        NSString *v1return = v1(vc);
        
        if (v1return != nil) {
            if (v2(vc) != nil) {
                return display;
            } else {
                return (NSString *)nil;
            }
        } else {
            return (NSString *)nil;
        }
    } copy];
}

-(id)initWithValidations:(NSArray *)vals {
    self = [super init];
    
    if (self != nil) {
        self.validations = vals;
    }
    
    return self;
}

-(BOOL)executeValidationsWithViewController:(UIViewController *)controller error:(NSString **)error {
    
    for(OTMValidatorValidation validation in self.validations) {
        NSString *result = validation(controller);
        
        if (result != nil) {
            *error = result;
            return NO;
        }
    }
    
    return YES;
}

-(BOOL)executeValidationsAndAlertWithViewController:(UIViewController *)controller {
    NSString *error = nil;
    
    BOOL success = [self executeValidationsWithViewController:controller error:&error];
    
    if (success) {
        return YES;
    } else {
        if (error != nil && [error length] > 0) {
            [[[UIAlertView alloc] initWithTitle:@"Form Errors"
                                       message:error
                                      delegate:nil
                             cancelButtonTitle:@"OK"
                             otherButtonTitles:nil] show];
        }
        
        return NO;
    }
}

@end

@implementation OTMTextFieldValidator

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

+(OTMValidatorValidation)isBlankValidation:(NSString *)field display:(NSString *)display {
    return [^(UIViewController *vc) {
        UITextField *textField = (id)[vc performSelector:NSSelectorFromString(field)];
        
        if ([textField.text length] > 0) {
            return [NSString stringWithFormat:@"%@ must be blank", display];
        } else {
            return (id)nil;
        }   
    } copy];    
}

+(OTMValidatorValidation)notBlankValidation:(NSString *)field display:(NSString *)display {
    return [OTMTextFieldValidator minLengthValidation:field display:display minLength:1];
}

+(OTMValidatorValidation)lengthValidation:(NSString *)field display:(NSString *)display length:(int)len {
    return [^(UIViewController *vc) {
        UITextField *textField = (id)[vc performSelector:NSSelectorFromString(field)];
        
        if ([textField.text length] != len) {
            return [NSString stringWithFormat:@"%@ must be at %d characters", display, len];
        } else {
            return (id)nil;
        }
    } copy];
}

+(OTMValidatorValidation)minLengthValidation:(NSString *)field display:(NSString *)display minLength:(int)len {
    return [^(UIViewController *vc) {
        UITextField *textField = (id)[vc performSelector:NSSelectorFromString(field)];
        
        if ([textField.text length] >= len) {
            return (id)nil; // NSString * helps determine return type of block
        } else {
            if (len == 1) {
                return [NSString stringWithFormat:@"%@ cannot be blank", display];
            } else {
                return [NSString stringWithFormat:@"%@ must be at least %d characters",     display, len];
            }
        }
    } copy];
}

+(OTMValidatorValidation)emailValidation:(NSString *)field display:(NSString *)display {
    return [^(UIViewController *vc) {
        UITextField *textField = (id)[vc performSelector:NSSelectorFromString(field)];
        
        //This regex was copied from the django regex in validators.py
        NSString *emailregex = @"(^[-!#$%&'*+/=?^_`{}|~0-9A-Z]+(\\.[-!#$%&'*+/=?^_`{}|~0-9A-Z]+)*|^\"([\001-\010\013\014\016-\037!#-\\[\\]-\177]|\\[\001-\011\013\014\016-\177])*\")@((?:[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?\\.)+[A-Z]{2,6}\\.?$)|\\[(25[0-5]|2[0-4]\\d|[0-1]?\\d?\\d)(\\.(25[0-5]|2[0-4]\\d|[0-1]?\\d?\\d)){3}\\]$";
        
        NSError *error;
        NSRegularExpression *regep = [NSRegularExpression regularExpressionWithPattern:emailregex options:NSRegularExpressionCaseInsensitive error:&error];
        
        BOOL valid = [regep numberOfMatchesInString:textField.text
                                            options:0
                                              range:NSMakeRange(0, [textField.text length])] == 1;        
        
        if (!valid) {
            return [NSString stringWithFormat:@"%@ must be a valid email address", display];
        } else {
            return (id)nil;
        }
    } copy];
}

#pragma clang diagnostic pop

@end
