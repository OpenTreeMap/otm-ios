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

+(UIImage *)stampForZoom:(MKZoomScale)zoom plot:(BOOL)plot {
    int baseScale = 18 + log2f(zoom); // OSM 18 level scale
    
    NSString *imageName;
    switch(baseScale) {
        case 10:
        case 11:
            imageName = @"tree_zoom1";
            break;
        case 12:
        case 13:
            imageName = @"tree_zoom3";
            break;
        case 14:
        case 15:
            imageName = @"tree_zoom5";
            break;
        case 16:
            imageName = @"tree_zoom6";
            break;
        case 17:
        case 18:
            imageName = @"tree_zoom7";
            break;
        default:
            imageName = @"tree_zoom1";
            break;
    }

    if (plot) {
        imageName = [NSString stringWithFormat:@"%@_plot", imageName];
    }

    
    return [UIImage imageNamed:imageName];
}

@end
