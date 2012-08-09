//
//  AZPointParser.m
//  OpenTreeMap
//
//  Created by Adam Hinz on 8/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AZPointParser.h"

@implementation AZPoint

@synthesize xoffset, yoffset, style;

-(id)initWithXOffset:(NSUInteger)xoff yOffset:(NSUInteger)yoff style:(NSUInteger)astyle {
    self = [super init];
    if (self) {
        xoffset = xoff;
        yoffset = yoff;
        style = astyle;
    }
    return self;
}

-(NSString *)description {
    return [NSString stringWithFormat:@"P(%d,%d)", xoffset, yoffset];
}

@end

@interface AZPointParser ()

+(int)parseSection:(NSData*)data    
            offset:(uint32_t)offset 
            points:(NSMutableArray *)points
             error:(NSError**)error;

@end

@implementation AZPointParser

+(NSArray *)parseData:(NSData *)data error:(NSError **)error {
    // Magic number
    uint32_t magic = 0;
                    
    if ([data length] < 8) {
        // Signal error? Invalid datastream (too small)
        NSDictionary *uinfo = [NSDictionary dictionaryWithObject:@"Header too short" forKey:@"error"];
        NSError* myError = [[NSError alloc] initWithDomain:@"otm.parse" 
                                                      code:0  
                                                  userInfo:uinfo];
                        
        *error = myError;
        return nil;
    }

    [data getBytes:&magic length:4];
                    
    uint32_t length = 0;
    uint32_t offset = 4;

    NSMutableArray *points = [NSMutableArray array];
                    
    [data getBytes:&length range:NSMakeRange(offset, 4)];
    offset += 4;
                    
    if (magic != 0xA3A5EA00) {
        NSDictionary *uinfo = [NSDictionary 
                                  dictionaryWithObject:@"Bad magic number (not 0xA3A5EA00)" 
                                                forKey:@"error"];

        NSError* myError = [[NSError alloc] initWithDomain:@"otm.parse" 
                                                      code:0  
                                                  userInfo:uinfo];                        
        *error = myError;

        return nil;
    }
                    
    NSError* sectionError = NULL;
                    
    while(offset < [data length] && [points count] < length) {
        offset = [self parseSection:data offset:offset points:points error:&sectionError];
                        
        if (sectionError != NULL) {                            
            *error = sectionError;
            return nil;
        }
    }

    return points;
}

+(int)parseSection:(NSData*)data    
            offset:(uint32_t)offset 
            points:(NSMutableArray *)points
             error:(NSError**)error {
    
    // Each section contains a simple header:
    // [1 byte type][2 byte length           ][1 byte pad]
    uint32_t sectionLength = 0;
    uint32_t sectionType = 0;
    
    [data getBytes:&sectionType range:NSMakeRange(offset, 1)];
    offset += 1;
    
    [data getBytes:&sectionLength range:NSMakeRange(offset, 2)];
    offset += 2;
    offset += 1; // Skip paddin

    NSUInteger x=0, y=0;

    for(int i=0;i<sectionLength;i++) {       
        x=0;
        y=0;
        [data getBytes:&x range:NSMakeRange(offset, 1)];
        offset += 1;
        
        [data getBytes:&y range:NSMakeRange(offset, 1)];
        offset += 1;
        
        AZPoint *p = [[AZPoint alloc] initWithXOffset:x
                                              yOffset:y
                                                style:sectionType];
        
        [points addObject:p];
    }
    
    
    return offset;   
}


@end
