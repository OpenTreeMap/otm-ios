//
//  AZTileRenderer.h
//  OpenTreeMap
//
//  Created by Adam Hinz on 5/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define AZTileHasTree 0x1
#define AZTileHasDBH 0x2
#define AZTileHasSpecies 0x4
#define AZTileFilterNone 0xff

typedef enum {
    AZTileFilterModeAny,
    AZTileFilterModeAll 
} AZTileFilterMode;

@interface AZTileRenderer : NSObject

+(UIImage*)createImageWithOffsets:(CFArrayRef)offsets zoomScale:(MKZoomScale)zoomScale alpha:(CGFloat)alpha;
+(UIImage*)createImageWithOffsets:(CFArrayRef)offsets zoomScale:(MKZoomScale)zoomScale alpha:(CGFloat)alpha filter:(u_char)filter mode:(AZTileFilterMode)mode;

+(UIImage *)stampForZoom:(MKZoomScale)zoom;

@end
