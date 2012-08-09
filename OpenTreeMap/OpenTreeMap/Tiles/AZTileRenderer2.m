//
//  AZTileRenderer2.m
//  OpenTreeMap
//
//  Created by Adam Hinz on 8/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AZTileRenderer2.h"
#import "AZPointParser.h"
#import "AZTile.h"
#import "AZTiler.h"

@implementation AZTileRenderer2

+(AZRenderedTile *)drawTile:(AZTile *)tile renderedTile:(AZRenderedTile *)rendered {
    if (rendered == nil) {
        rendered = [[AZRenderedTile alloc] init];
    }

    CGSize frameSize = CGSizeMake(256, 256);
    UIGraphicsBeginImageContext(frameSize);

    // If there is no image, then we start be drawing the main points
    if (rendered.image == nil) {
        [self drawImage:tile.points 
              zoomScale:tile.zoomScale
                xOffset:0
                yOffset:0];
    } else { // Otherwise, draw the image
        [rendered.image drawInRect:CGRectMake(0,0,256,256) blendMode:kCGBlendModeNormal alpha:1.0];
    }

    for(AZDirection dir in [[tile borderTiles] allKeys]) {
        // Directions only need to be drawn if they are in the pending list
        if ([rendered.pendingEdges containsObject:dir]) {
            [rendered.pendingEdges removeObject:dir];

            CGFloat xoff = 0.0f, yoff = 0.0f;
            if ([dir isEqualToString:kAZNorth]) {     xoff = 0.0f;  yoff = -1.0; }
            if ([dir isEqualToString:kAZNorthEast]) { xoff = 1.0f;  yoff = -1.0; }
            if ([dir isEqualToString:kAZEast]) {      xoff = 1.0f;  yoff = 0.0; }
            if ([dir isEqualToString:kAZSouthEast]) { xoff = 1.0f;  yoff = 1.0; }
            if ([dir isEqualToString:kAZSouth]) {     xoff = 0.0f;  yoff = 1.0; }
            if ([dir isEqualToString:kAZSouthWest]) { xoff = -1.0f; yoff = 1.0; }
            if ([dir isEqualToString:kAZWest]) {      xoff = -1.0f; yoff = 0.0; }
            if ([dir isEqualToString:kAZNorthWest]) { xoff = -1.0f; yoff = -1.0; }
            xoff *= 256.0;
            yoff *= -256.0;

            [self drawImage:[[tile borderTiles] objectForKey:dir]
                  zoomScale:tile.zoomScale
                    xOffset:xoff
                    yOffset:yoff];        

        }
    }
            

    // [[UIColor redColor] setStroke];
    // CGContextStrokeRect(UIGraphicsGetCurrentContext(), CGRectMake(0,0,256,256));

    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsPopContext();

    rendered.image = image;
    return rendered;
}

+(void)drawImage:(NSArray *)points
       zoomScale:(MKZoomScale)zoomScale
         xOffset:(CGFloat)xoffset
         yOffset:(CGFloat)yoffset {

    BOOL plot = (xoffset != 0.0 || yoffset != 0.0);

    for(AZPoint *p in points) {        
        UIImage *stamp = [self stampForZoom:zoomScale plot:plot];

        CGRect baseRect = CGRectMake(-stamp.size.width / 2.0f,
                                     -stamp.size.height / 2.0f,
                                     stamp.size.width, stamp.size.height);
    
        CGRect rect = CGRectOffset(baseRect, p.xoffset + xoffset, 255 - p.yoffset + yoffset);

        [stamp drawInRect:rect blendMode:kCGBlendModeNormal alpha:1.0];
    }
}

+(NSArray *)stamps {
    static NSMutableArray *stamps = nil;
    if (!stamps) {
        stamps = [NSMutableArray array];

        // Stamp objects start at Zoom Level 10
        // Regular trees
        [stamps addObject:[UIImage imageNamed:@"tree_zoom1"]]; // Level 10
        [stamps addObject:[UIImage imageNamed:@"tree_zoom1"]]; // Level 11
        [stamps addObject:[UIImage imageNamed:@"tree_zoom3"]]; // Level 12
        [stamps addObject:[UIImage imageNamed:@"tree_zoom3"]]; // Level 13
        [stamps addObject:[UIImage imageNamed:@"tree_zoom5"]]; // Level 14
        [stamps addObject:[UIImage imageNamed:@"tree_zoom5"]]; // Level 15
        [stamps addObject:[UIImage imageNamed:@"tree_zoom6"]]; // Level 16
        [stamps addObject:[UIImage imageNamed:@"tree_zoom7"]]; // Level 17
        [stamps addObject:[UIImage imageNamed:@"tree_zoom7"]]; // Level 18

        // Plots
        [stamps addObject:[UIImage imageNamed:@"tree_zoom1_plot"]]; // Level 10
        [stamps addObject:[UIImage imageNamed:@"tree_zoom1_plot"]]; // Level 11
        [stamps addObject:[UIImage imageNamed:@"tree_zoom3_plot"]]; // Level 12
        [stamps addObject:[UIImage imageNamed:@"tree_zoom3_plot"]]; // Level 13
        [stamps addObject:[UIImage imageNamed:@"tree_zoom5_plot"]]; // Level 14
        [stamps addObject:[UIImage imageNamed:@"tree_zoom5_plot"]]; // Level 15
        [stamps addObject:[UIImage imageNamed:@"tree_zoom6_plot"]]; // Level 16
        [stamps addObject:[UIImage imageNamed:@"tree_zoom7_plot"]]; // Level 17
        [stamps addObject:[UIImage imageNamed:@"tree_zoom7_plot"]]; // Level 18

        // Highlight (same for all levels)
        [stamps addObject:[UIImage imageNamed:@"tree_zoom7_highlight"]]; // Level 10
        [stamps addObject:[UIImage imageNamed:@"tree_zoom7_highlight"]]; // Level 11
        [stamps addObject:[UIImage imageNamed:@"tree_zoom7_highlight"]]; // Level 12
        [stamps addObject:[UIImage imageNamed:@"tree_zoom7_highlight"]]; // Level 13
        [stamps addObject:[UIImage imageNamed:@"tree_zoom7_highlight"]]; // Level 14
        [stamps addObject:[UIImage imageNamed:@"tree_zoom7_highlight"]]; // Level 15
        [stamps addObject:[UIImage imageNamed:@"tree_zoom7_highlight"]]; // Level 16
        [stamps addObject:[UIImage imageNamed:@"tree_zoom7_highlight"]]; // Level 17
        [stamps addObject:[UIImage imageNamed:@"tree_zoom7_highlight"]]; // Level 18


    }

    return stamps;
}
    


+(UIImage *)stampForZoom:(MKZoomScale)zoom plot:(BOOL)plot {
    int baseScale = 18 + log2f(zoom); // OSM 18 level scale
    baseScale = MAX(baseScale, kAZTileRendererStampFirstLevel);
    return [[self stamps] objectAtIndex:
            (baseScale - kAZTileRendererStampFirstLevel + (plot? kAZTileRendererStampOffsetPlot : 0))];
}

@end
