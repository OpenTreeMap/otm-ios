/*

 OTMMapDetailCellRenderer.h

 Created by Justin Walgran on 5/14/12.

 License
 =======
 Copyright (c) 2012 Azavea. All rights reserved.

 Permission is hereby granted, free of charge, to any person obtaining a copy 
 of this software and associated documentation files (the "Software"), to deal 
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
 copies of the Software, and to permit persons to whom the Software is furnished
 to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
*/

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

/**
 * Free the pointer and set the length to zero
 */
-(void)invalidate;

@end
