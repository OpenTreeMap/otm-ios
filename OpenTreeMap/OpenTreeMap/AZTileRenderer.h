//
//  AZTileRenderer.h
//  OpenTreeMap
//
//  Created by Adam Hinz on 5/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTMAPI.h"
#import "AZGeoCache.h"

#define AZTileHasTree 0x1
#define AZTileHasDBH 0x2
#define AZTileHasSpecies 0x4
#define AZTileFilterNone 0xff

typedef void(^AZRefreshCallback)(MKMapRect m, MKZoomScale z);

typedef enum {
    AZTileFilterModeAny,
    AZTileFilterModeAll,
    AZTileFilterModeNone,
    AZTileFilterForceFilter
} AZTileFilterMode;

@interface AZTileRenderer : NSObject

+(void)createImageWithPoints:(AZPointCollection *)pcol
                       error:(NSError *)err 
                     mapRect:(MKMapRect)mapRect
                   zoomScale:(MKZoomScale)zoomScale
                   tileAlpha:(CGFloat)tileAlpha
                     filters:(OTMFilters *)fs
                   tileCache:(AZGeoCache *)tileCache
                  pointCache:(AZGeoCache *)pointCache
      displayRequestCallback:(AZRefreshCallback)cb;

+(UIImage*)createImageWithOffsets:(CFArrayRef)offsets zoomScale:(MKZoomScale)zoomScale alpha:(CGFloat)alpha;
+(UIImage*)createFilterImageWithOffsets:(CFArrayRef)offsets zoomScale:(MKZoomScale)zoomScale alpha:(CGFloat)alpha filters:(OTMFilters *)f;
+(UIImage*)createImageWithOffsets:(CFArrayRef)offsets zoomScale:(MKZoomScale)zoomScale alpha:(CGFloat)alpha filter:(u_char)filter mode:(AZTileFilterMode)mode;

+(UIImage *)stampForZoom:(MKZoomScale)zoom hasTree:(BOOL)hastree;
+(CGSize)largestStampSize;


@end
