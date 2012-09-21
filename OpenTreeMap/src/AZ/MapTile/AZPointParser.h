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
