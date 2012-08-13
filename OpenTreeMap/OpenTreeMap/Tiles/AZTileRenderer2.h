//
//  AZTileRenderer2.h
//  OpenTreeMap
//
//  Created by Adam Hinz on 8/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AZTile.h"
#import "AZTiler.h"
#import "OTMFilterListViewController.h"

#define kAZTileRendererStampFirstLevel 10
#define kAZTileRendererStampLastLevel 18
#define kAZTileRendererStampOffsetRegular 0
#define kAZTileRendererStampOffsetPlot ((kAZTileRendererStampLastLevel - \
                                         kAZTileRendererStampFirstLevel)+1)

#define kAZTileRendererStampOffsetHighlight (kAZTileRendererStampOffsetPlot + \
                                             (kAZTileRendererStampLastLevel - \
                                              kAZTileRendererStampFirstLevel)+1)

typedef NSUInteger AZPointStyle;

@interface AZTileRenderer2 : NSObject

+(AZRenderedTile *)createTile:(AZTile *)tile renderedTile:(AZRenderedTile *)rendered filters:(OTMFilters *)filters;

+(UIImage *)stampForZoom:(MKZoomScale)zoom plot:(BOOL)plot;


+(void)drawImage:(AZPointerArrayWrapper *)points
       zoomScale:(MKZoomScale)zoomScale
         xOffset:(CGFloat)xoffset
         yOffset:(CGFloat)yoffset
         context:(CGContextRef)context
         filters:(OTMFilters *)filters;

@end
