//
//  NSDictionary+MutableDeepCopy.m
//  OpenTreeMap
//
//  Created by Adam Hinz on 4/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSDictionary+MutableDeepCopy.h"

@implementation NSDictionary (MutableDeepCopy)

-(NSMutableDictionary *)mutableDeepCopy {
    NSMutableDictionary *mself = [NSMutableDictionary dictionary];
    
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        id mObj = nil;
        
        if ([obj respondsToSelector:@selector(mutableDeepCopy)]) {
            mObj = [obj mutableDeepCopy];
        } else if ([obj respondsToSelector:@selector(mutableCopyWithZone:)]) {
            mObj = [obj mutableCopy];
        } else {
            mObj = obj;
        }
        
        [mself setObject:mObj forKey:key];
    }];
    
    return mself;
}


@end
