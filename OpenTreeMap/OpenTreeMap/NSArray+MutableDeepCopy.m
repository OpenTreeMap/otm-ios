//
//  NSArray+MutableDeepCopy.m
//  OpenTreeMap
//
//  Created by Adam Hinz on 4/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSArray+MutableDeepCopy.h"

@implementation NSArray (MutableDeepCopy)

-(NSMutableArray *)mutableDeepCopy {
    NSMutableArray *marr = [NSMutableArray array];
    
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id mObj = nil;
        
        if ([obj respondsToSelector:@selector(mutableDeepCopy)]) {
            mObj = [obj mutableDeepCopy];
        } else if ([obj respondsToSelector:@selector(mutableCopy)]) {
            mObj = [obj mutableCopy];
        } else {
            mObj = obj;
        }
        
        [marr addObject:mObj];
    }];
    
    return marr;
}

@end
