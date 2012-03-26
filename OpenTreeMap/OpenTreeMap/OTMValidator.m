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

#import "OTMValidator.h"

@implementation OTMValidator

@synthesize validations;


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

+(OTMValidatorValidation)isBlankValidation:(NSString *)field display:(NSString *)display {
    return [^(UIViewController *vc) {
        UITextField *textField = (id)[vc performSelector:NSSelectorFromString(field)];
        
        if ([textField.text length] > 0) {
            return [NSString stringWithFormat:@"%@ must be blank", display];
        } else {
            return nil;
        }   
    } copy];    
}

+(OTMValidatorValidation)notBlankValidation:(NSString *)field display:(NSString *)display {
    return [OTMValidator minLengthValidation:field display:display minLength:1];
}

+(OTMValidatorValidation)lengthValidation:(NSString *)field display:(NSString *)display length:(int)len {
    return [^(UIViewController *vc) {
        UITextField *textField = (id)[vc performSelector:NSSelectorFromString(field)];
        
        if ([textField.text length] != len) {
            return [NSString stringWithFormat:@"%@ must be at %d characters", display, len];
        } else {
            return nil;
        }
    } copy];
}

+(OTMValidatorValidation)minLengthValidation:(NSString *)field display:(NSString *)display minLength:(int)len {
    return [^(UIViewController *vc) {
        UITextField *textField = (id)[vc performSelector:NSSelectorFromString(field)];
        
        if ([textField.text length] >= len) {
            return (NSString*)nil; // NSString * helps determine return type of block
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
            return nil;
        }
    } copy];
}

+(OTMValidatorValidation)validation:(OTMValidatorValidation)v1 or:(OTMValidatorValidation)v2 display:(NSString *)display {
    return [^(UIViewController *vc) {
        NSString *v1return = v1(vc);
        
        if (v1return != nil) {
            if (v2(vc) != nil) {
                return display;
            } else {
                return nil;
            }
        } else {
            return nil;
        }
    } copy];
}

#pragma clang diagnostic pop

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
