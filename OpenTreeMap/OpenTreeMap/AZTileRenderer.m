//
//  AZTileRenderer.m
//  OpenTreeMap
//
//  Created by Adam Hinz on 5/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AZTileRenderer.h"

@implementation AZTileRenderer

+(UIImage*)createImageWithOffsets:(CFArrayRef)offsets zoomScale:(MKZoomScale)zoomScale alpha:(CGFloat)alpha {
    return [self createImageWithOffsets:offsets zoomScale:zoomScale alpha:alpha filter:AZTileFilterNone mode:AZTileFilterModeNone];
}

+(UIImage*)createImageWithOffsets:(CFArrayRef)offsets zoomScale:(MKZoomScale)zoomScale alpha:(CGFloat)alpha filter:(u_char)filter mode:(AZTileFilterMode)mode {
    UIImage *stamp = [AZTileRenderer stampForZoom:zoomScale filter:filter];

    CGSize imageSize = [stamp size];
    CGSize frameSize = CGSizeMake(256 + imageSize.width * 2, 256 + imageSize.height * 2);
    UIGraphicsBeginImageContext(frameSize);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(context);

    CGRect baseRect = CGRectMake(-imageSize.width / 2.0f + imageSize.width, 
                                 -imageSize.height / 2.0f + imageSize.height, 
                                 imageSize.width, imageSize.height);
    
    for(int i=0;i<CFArrayGetCount(offsets);i++) {
        const OTMPoint* p = CFArrayGetValueAtIndex(offsets, i);
        
        if ([self pointIsFiltered:p withMode:mode filter:filter]) {
            CGRect rect = CGRectOffset(baseRect, p->xoffset, 255 - p->yoffset);
        
            [stamp drawInRect:rect blendMode:kCGBlendModeNormal alpha:alpha];
        }
    }
    
    UIGraphicsPopContext();
    
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

+(BOOL)pointIsFiltered:(const OTMPoint *)p withMode:(AZTileFilterMode)mode filter:(u_char)filter {
    BOOL draw = YES;
    if (mode == AZTileFilterModeNone) {
        draw = YES;
    } else if (mode == AZTileFilterModeAny) {
        if ((p->style & filter) != 0) {
            draw = NO;
        }
    } else if (mode == AZTileFilterModeAll) {
        if (p->style == filter) {
            draw = NO;
        }
    }
    return draw;
}

+(UIImage *)stampForZoom:(MKZoomScale)zoom {
    return [AZTileRenderer stampForZoom:zoom filter:AZTileFilterNone];
}

+(UIImage *)stampForZoom:(MKZoomScale)zoom filter:(u_char)filter {
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
    
    if (filter != AZTileFilterNone) {
        imageName = [NSString stringWithFormat:@"%@_plot",imageName];
    }
    
    return [UIImage imageNamed:imageName];
}

@end
