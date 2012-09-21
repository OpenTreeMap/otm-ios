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

#import "AZPointParser.h"

Function1v parserFreePoints() {
    return ^(AZPointerArrayWrapper *par) {
        AZPoint **p = (AZPoint **)par.pointer;
        NSUInteger length = par.length;
        for(int i=0;i<length;i++) {
            void *ptr = p[i];
            if (ptr != NULL) {
                free(ptr);
            }
        }
        free(p);
    };
}

/**
 * Parse the raw byte data
 *
 * @param bytes the data
 * @return array of AZPoints
 * @return nPoints number of points
 */
AZPoint** parseData(const uint8_t *bytes, uint32_t length, uint32_t *nPoints_ptr, AZPointParserError *error) {
    if (bytes == NULL) {
        *error = AZPointParserBadLength;
        return NULL;
    }
    if (length < 8) {
        *error = AZPointParserBadLength;
        return NULL;
    }

    if (bytes[3] != 0xA3 || // 0xA3A5EA <--> AZAVEA lolz
        bytes[2] != 0xA5 ||
        bytes[1] != 0xEA ||
        bytes[0] != 0x00) {
        *error = AZPointParserBadMagicNumber;
        return NULL;
    }

    uint32_t nPoints = (bytes[7] << 24) | (bytes[6] << 16) | (bytes[5] << 8) | bytes[4];
    *nPoints_ptr = nPoints;

    uint32_t offset = 8; // Start at 8 (4 byte magic and 4 byte length)
    
    AZPoint **points = malloc(sizeof(AZPoint*) * nPoints);
    uint32_t point_offset = 0;

    AZPointParserError err = 0;
                                        
    while(offset < length && point_offset < nPoints) {
        offset = parseSection(bytes, offset, length, points, &point_offset, nPoints, &err);

        if (err != 0) {
            *error = err;
            return NULL;
        }
    }

    return points;    
}

/**
 * Parse the raw byte data given for a section into points
 *
 * @param bytes the raw byte data
 * @param byte_offset the current offset in the byte data
 * @param byte_len length of byte array
 * @param points array of points to write to
 * @param point_offset_ptr pointer to where to write the next point
 * @param point_array_len length of point array
 * @param error_ptr error return value
 *
 * @return the new byte offset
 * @return point_offset will be updated based on the number of poitns written
 * @return error - a string describing a potential error state
 */
static uint32_t parseSection(const uint8_t *bytes, uint32_t byte_offset, uint32_t byte_len,
                      AZPoint **points, uint32_t *point_offset_ptr, uint32_t points_array_len, 
                      AZPointParserError *error) {

    if (bytes == NULL) {
        *error = AZPointParserBadLength;
        return 0;
    }

    if (byte_offset + 3 >= byte_len) {
        *error = AZPointParserBufferOverflow;
        return 0;
    }

    uint32_t point_offset = *point_offset_ptr;
    
    // Each section contains a simple header:
    // [1 byte type][2 byte length           ][1 byte pad]
    uint16_t sectionLength = 0;
    uint8_t sectionType = 0;
    
    sectionType = bytes[byte_offset];
    byte_offset += 1;

    sectionLength = (bytes[byte_offset + 1] << 8) | bytes[byte_offset];
    byte_offset += 2;

    byte_offset += 1; // Skip padding

    // We're going to read (sectionLength * 2) bytes
    // and insert (sectionLength) bytes into the array
    if ((byte_offset + sectionLength * 2) > byte_len) {
        *error = AZPointParserBufferOverflow;
        return 0;
    }

    if ((point_offset + sectionLength > points_array_len) || point_offset >= points_array_len) {
        *error = AZPointParserBufferOverflow;
        return 0;
    }

    uint8_t x=0, y=0;

    for(int i=0;i<sectionLength;i++) {       
        x = bytes[byte_offset];
        byte_offset += 1;

        y = bytes[byte_offset];
        byte_offset += 1;

        AZPoint *p = malloc(sizeof(AZPoint));
        if (p == NULL) {
            *error = AZPointParserMallocError;
            return 0;
        }

        p->xoffset = x;
        p->yoffset = y;
        p->style = sectionType;
        
        points[point_offset] = p;
        point_offset++;
    }
    
    *point_offset_ptr = point_offset;
    return byte_offset;   

}

@implementation AZPointerArrayWrapper

@synthesize pointer;
@synthesize length;

-(id)initWithPointer:(void **)p length:(NSUInteger)l deallocCallback:(Function1v)cb {
    self = [super init];

    if (self) {
        pointer = p;
        deallocCallback = cb;
        length = l;
    }

    return self;
}

-(void **)pointer {
    if (pointer == NULL) {
        [NSException raise:@"Invalid pointer access" format:@""];
    }
    return pointer;
}

+(AZPointerArrayWrapper *)wrapperWithPointer:(void **)p length:(NSUInteger)l deallocCallback:(Function1v)cb {
    return [[AZPointerArrayWrapper alloc] initWithPointer:p length:l deallocCallback:cb];
}

-(void)invalidate {
    if (deallocCallback) {
        deallocCallback(self);
    }
    length = 0;
    pointer = NULL;
}

-(void)dealloc {
    [self invalidate];
}

@end
