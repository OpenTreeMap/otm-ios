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

@interface AZTileRenderer : NSObject

+(AZRenderedTile *)createTile:(AZTile *)tile renderedTile:(AZRenderedTile *)rendered filters:(OTMFilters *)filters;

+(UIImage *)stampForZoom:(MKZoomScale)zoom plot:(BOOL)plot;


+(void)drawImage:(AZPointerArrayWrapper *)points
       zoomScale:(MKZoomScale)zoomScale
         xOffset:(CGFloat)xoffset
         yOffset:(CGFloat)yoffset
         context:(CGContextRef)context
         filters:(OTMFilters *)filters;

@end
