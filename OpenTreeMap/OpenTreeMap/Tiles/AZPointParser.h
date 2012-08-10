//
//  AZPointParser.h
//  OpenTreeMap
//
//  Created by Adam Hinz on 8/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct { 
    uint8_t xoffset; 
    uint8_t yoffset; 
    uint8_t style; 
} AZPoint;

typedef enum {
    AZPointParserBadLength = 1,
    AZPointParserBadMagicNumber = 2,
    AZPointParserBufferOverflow = 3,
    AZPointParserMallocError = 4
} AZPointParserError;

/**
 * Parse the raw byte data
 *
 * @param bytes the data
 * @return array of AZPoints
 * @return nPoints_ptr number of points in the returned array
 */
AZPoint** parseData(const uint8_t *bytes, uint32_t length, uint32_t *nPoints_ptr, AZPointParserError *error);

static uint32_t parseSection(const uint8_t *bytes, uint32_t byte_offset, uint32_t byte_len,
                             AZPoint **points, uint32_t *point_offset_ptr, uint32_t points_array_len, 
                             AZPointParserError *error);

/**
 * Callback block that can be used to free the data structure returned by
 * parse data
 */
Function1v parserFreePoints();


/**
 * Wraps a pointer with a dealloc callback
 */
@interface AZPointerArrayWrapper : NSObject {
    void ** pointer;
    Function1v deallocCallback;
    NSUInteger length;
}

@property (nonatomic,readonly) void** pointer;
@property (nonatomic,readonly) NSUInteger length;

-(id)initWithPointer:(void **)p length:(NSUInteger)length deallocCallback:(Function1v)cb;
+(AZPointerArrayWrapper *)wrapperWithPointer:(void **)p length:(NSUInteger)length deallocCallback:(Function1v)cb;

@end
