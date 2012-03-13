//
//  NSString+Base64.m
//  OpenTreeMap
//
//  Created by Adam Hinz on 3/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSString+Base64.h"

@implementation NSString (Base64)

-(NSString*)base64String {
    return [[self dataUsingEncoding:NSUTF8StringEncoding] base64String];
}

@end
