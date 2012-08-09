//
//  AZPointParser.h
//  OpenTreeMap
//
//  Created by Adam Hinz on 8/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AZPoint : NSObject

@property (nonatomic,readonly,assign) NSUInteger xoffset;
@property (nonatomic,readonly,assign) NSUInteger yoffset;
@property (nonatomic,readonly,assign) NSUInteger style;

-(id)initWithXOffset:(NSUInteger)xoff yOffset:(NSUInteger)yoff style:(NSUInteger)style;

@end

@interface AZPointParser : NSObject

+(NSArray *)parseData:(NSData *)data error:(NSError **)error;

@end
