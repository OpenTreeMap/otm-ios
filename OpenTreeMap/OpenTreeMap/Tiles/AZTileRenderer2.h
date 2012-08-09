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

@interface AZTileRenderer2 : NSObject

+(AZRenderedTile *)drawTile:(AZTile *)tile renderedTile:(AZRenderedTile *)rendered;

+(UIImage *)stampForZoom:(MKZoomScale)zoom plot:(BOOL)plot;

+(void)drawImage:(NSArray *)points
       zoomScale:(MKZoomScale)zoomScale
         xOffset:(CGFloat)xoffset
         yOffset:(CGFloat)yoffset;

@end
