//
//  AZTileRenderer.m
//  OpenTreeMap
//
//  Created by Adam Hinz on 5/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AZTileRenderer.h"

typedef enum {
    North = 1,
    NorthEast,
    East,
    SouthEast,
    South,
    SouthWest,
    West,
    NorthWest
} OTMDirection;


@implementation AZTileRenderer

+(OTMDirection)oppositeDir:(OTMDirection)dir {
    switch (dir) {
        case North:
            return South;
        case NorthEast:
            return SouthWest;
        case East:
            return West;
        case SouthEast:   
            return NorthWest;
        case South:   
            return North;
        case SouthWest:   
            return NorthEast;
        case West:
            return East;
        case NorthWest:
            return SouthEast;
        default:
            return North;
    }
}

+(MKMapRect)mapRectForNeighbor:(MKMapRect)rect direction:(OTMDirection)dir {
    switch (dir) {
        case North:
            rect = MKMapRectOffset(rect, 0, -rect.size.height);
            break;
        case NorthEast:
            rect = MKMapRectOffset(rect, rect.size.width, -rect.size.height);
            break;
        case East:
            rect = MKMapRectOffset(rect, rect.size.width, 0);
            break;
        case SouthEast:
            rect = MKMapRectOffset(rect, rect.size.width, rect.size.height);
            break;
        case South:
            rect = MKMapRectOffset(rect, 0, rect.size.height);
            break;
        case SouthWest:
            rect = MKMapRectOffset(rect, -rect.size.width, rect.size.height);
            break;
        case West:
            rect = MKMapRectOffset(rect, -rect.size.width, 0);
            break;
        case NorthWest:
            rect = MKMapRectOffset(rect, -rect.size.width, -rect.size.height);
            break;
        default:
            break;
    }
    
    return rect;
}

+(UIImage *)fillInBorders:(UIImage *)image mapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale tileCache:(AZGeoCache *)tiles alpha:(CGFloat)alpha  {

    UIGraphicsBeginImageContext([image size]);
    [image drawInRect:CGRectMake(0,0,image.size.width,image.size.height)];

    CGSize stampSize = [AZTileRenderer largestStampSize];

    for(OTMDirection dir=North;dir<=NorthWest;dir++) {
        [self drawNeighbor:dir mapRect:mapRect zoomScale:zoomScale stampSize:stampSize alpha:alpha cache:tiles image:image];
    }

    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsPopContext();

    return newImage;
}

+(void)drawNeighbor:(OTMDirection)dir mapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale stampSize:(CGSize)stampSize alpha:(CGFloat)alpha cache:(AZGeoCache *)cache image:(UIImage*)image {
   
    CGFloat offsetX = 0;
    CGFloat offsetY = 0;
    
    CGFloat stampHeightOffset = (stampSize.height);
    CGFloat stampWidthOffset = (stampSize.width);
    CGRect centerRect = CGRectMake(0, 0, image.size.width, image.size.height);
    
    switch (dir) {
        case North:
            offsetX = 0;
            offsetY = -centerRect.size.height + stampHeightOffset;
            break;
        case NorthEast:
            offsetX = centerRect.size.width - stampWidthOffset;
            offsetY = -centerRect.size.height + stampHeightOffset;
            break;
        case East:
            offsetX = centerRect.size.width - stampWidthOffset;
            offsetY = 0;
            break;
        case SouthEast:   
            offsetX = centerRect.size.width - stampWidthOffset;
            offsetY = centerRect.size.height - stampHeightOffset;
            break;
        case South:   
            offsetX = 0;
            offsetY = centerRect.size.height - stampHeightOffset;
            break;
        case SouthWest:   
            offsetX = -centerRect.size.width + stampWidthOffset;
            offsetY = centerRect.size.height - stampHeightOffset;
            break;
        case West:
            offsetX = -centerRect.size.width + stampWidthOffset;
            offsetY = 0;
            break;      
        case NorthWest:
            offsetX = -centerRect.size.width + stampWidthOffset;
            offsetY = -centerRect.size.height + stampHeightOffset;
            break;            
            
        default:
            break;
    }

    MKMapRect neighMapRect = [self mapRectForNeighbor:mapRect direction:dir];    
    UIImage *neigh = [cache getObjectForMapRect:neighMapRect zoomScale:zoomScale];
    
    if (neigh) {
        CGRect newRect = CGRectMake(offsetX,offsetY,neigh.size.width,neigh.size.height); 
        [neigh drawInRect:newRect blendMode:kCGBlendModeNormal alpha:alpha];   
    }        
}

+(UIImage *)fillInImage:(UIImage *)image fromCenterImage:(UIImage *)cimage directionFromCenter:(OTMDirection)dirFrom stampSize:(CGSize)stampSize  {
    CGFloat offsetX = 0;
    CGFloat offsetY = 0;

    OTMDirection dir = [self oppositeDir:dirFrom];
    
    CGFloat stampHeightOffset = (stampSize.height);
    CGFloat stampWidthOffset = (stampSize.width);
    CGRect centerRect = CGRectMake(0, 0, image.size.width, image.size.height);
    
    switch (dir) {
        case North:
            offsetX = 0;
            offsetY = -centerRect.size.height + stampHeightOffset;
            break;
        case NorthEast:
            offsetX = centerRect.size.width - stampWidthOffset;
            offsetY = -centerRect.size.height + stampHeightOffset;
            break;
        case East:
            offsetX = centerRect.size.width - stampWidthOffset;
            offsetY = 0;
            break;
        case SouthEast:   
            offsetX = centerRect.size.width - stampWidthOffset;
            offsetY = centerRect.size.height - stampHeightOffset;
            break;
        case South:   
            offsetX = 0;
            offsetY = centerRect.size.height - stampHeightOffset;
            break;
        case SouthWest:   
            offsetX = -centerRect.size.width + stampWidthOffset;
            offsetY = centerRect.size.height - stampHeightOffset;
            break;
        case West:
            offsetX = -centerRect.size.width + stampWidthOffset;
            offsetY = 0;
            break;      
        case NorthWest:
            offsetX = -centerRect.size.width + stampWidthOffset;
            offsetY = -centerRect.size.height + stampHeightOffset;
            break;            
            
        default:
            break;
    }

    UIGraphicsBeginImageContext([image size]);

    [image drawInRect:CGRectMake(0,0,image.size.width,image.size.height)];

    CGRect newRect = CGRectMake(offsetX,offsetY,image.size.width,image.size.height); 
    [cimage drawInRect:newRect];

    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsPopContext();

    return newImage;
}

+(void)createImageWithPoints:(AZPointCollection *)pcol
                       error:(NSError *)error
                     mapRect:(MKMapRect)mapRect
                   zoomScale:(MKZoomScale)zoomScale
                   tileAlpha:(CGFloat)tileAlpha
                     filters:(OTMFilters *)fs
                   tileCache:(AZGeoCache *)tileCache
                  pointCache:(AZGeoCache *)pointCache
      displayRequestCallback:(AZRefreshCallback)cb {
    if (error == nil && [tileCache getObjectForMapRect:mapRect zoomScale:zoomScale] == nil) {
        NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
             
        CFArrayRef points = pcol.points;

        NSTimeInterval start1 = [NSDate timeIntervalSinceReferenceDate];
        UIImage *image;
        if (fs) {
            image = [AZTileRenderer createFilterImageWithOffsets:points zoomScale:zoomScale alpha:tileAlpha filters:fs];
        } else {
            image = [AZTileRenderer createImageWithOffsets:points zoomScale:zoomScale alpha:tileAlpha];
        }

        @synchronized(self) {
            NSLog(@"\t -> %0.3f second for initial render",[NSDate timeIntervalSinceReferenceDate]-start1);

            image = [self fillInBorders:image mapRect:mapRect zoomScale:zoomScale tileCache:tileCache alpha:tileAlpha];
             
            [pointCache cacheObject:pcol forMapRect:mapRect zoomScale:zoomScale];
            [tileCache cacheObject:image forMapRect:mapRect zoomScale:zoomScale];

            CGSize stampSize = [AZTileRenderer largestStampSize];

            for(OTMDirection dir=North;dir<=NorthWest;dir++) {                    
                MKMapRect neighMapRect = [self mapRectForNeighbor:mapRect direction:dir];
                UIImage *neighborImage = [tileCache getObjectForMapRect:neighMapRect zoomScale:zoomScale];
                if (neighborImage) {
                    neighborImage = [self fillInImage:neighborImage fromCenterImage:image directionFromCenter:dir stampSize:stampSize];

                    [tileCache cacheObject:neighborImage forMapRect:neighMapRect zoomScale:zoomScale];
                    if (cb) { cb(neighMapRect, zoomScale); }
                }
            }

        }

        if (cb) { cb(mapRect, zoomScale); }

        NSTimeInterval end = [NSDate timeIntervalSinceReferenceDate];
        NSLog(@"Took %0.3f seconds to render",end-start);
    } else {
        if (error != nil) {
            NSLog(@"Error loading tile images: %@", error);
        } else {
            NSLog(@"This tile is already cached.");
        }
    }
}


+(UIImage*)createFilterImageWithOffsets:(CFArrayRef)offsets zoomScale:(MKZoomScale)zoomScale alpha:(CGFloat)alpha filters:(OTMFilters *)f {
    int filter = 0;
    if (f.missingDBH) { filter |= AZTileHasDBH; }
    if (f.missingTree) { filter |= AZTileHasTree; }
    if (f.missingSpecies) { filter |= AZTileHasSpecies; }

    return [self createImageWithOffsets:offsets zoomScale:zoomScale alpha:alpha filter:filter mode:AZTileFilterModeAny];
}

+(UIImage*)createImageWithOffsets:(CFArrayRef)offsets zoomScale:(MKZoomScale)zoomScale alpha:(CGFloat)alpha {
    return [self createImageWithOffsets:offsets zoomScale:zoomScale alpha:alpha filter:AZTileFilterNone mode:AZTileFilterModeNone];
}

+(UIImage*)createImageWithOffsets:(CFArrayRef)offsets zoomScale:(MKZoomScale)zoomScale alpha:(CGFloat)alpha filter:(u_char)filter mode:(AZTileFilterMode)mode {
    // We need to know the image size ahead of time to determine the frame border buffer
    CGSize imageSize = [AZTileRenderer largestStampSize];
    CGSize frameSize = CGSizeMake(256 + imageSize.width, 256 + imageSize.height);
    UIGraphicsBeginImageContext(frameSize);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(context);

    for(int i=0;i<CFArrayGetCount(offsets);i++) {
        const OTMPoint* p = CFArrayGetValueAtIndex(offsets, i);
        
        if ([self point:p isFilteredWithMode:mode filter:filter]) {
            UIImage *stamp = [AZTileRenderer stampForZoom:zoomScale filter:filter mode:mode hasTree:((p->style & AZTileHasTree) > 0)];

            CGRect baseRect = CGRectMake(imageSize.width / 2.0f - stamp.size.width / 2.0f, // Offset for border
                                         imageSize.height / 2.0f - stamp.size.height / 2.0f,
                                         stamp.size.width, stamp.size.height);
    
            CGRect rect = CGRectOffset(baseRect, p->xoffset, 255 - p->yoffset);

            [stamp drawInRect:rect blendMode:kCGBlendModeNormal alpha:alpha];
        }
    }

    // DEBUG tile overlap issues
    // [[UIColor blueColor] setStroke];
    // CGContextStrokeRect(context, CGRectMake(imageSize.width/2.0f, imageSize.height/2.0f, 
    //                                         frameSize.width-imageSize.width/2.0f,frameSize.height-imageSize.height/2.0f));
    // [[UIColor redColor] setStroke];
    // CGContextStrokeRect(context, CGRectMake(0,0,frameSize.width,frameSize.height));

    UIGraphicsPopContext();
    
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

+(CGSize)largestStampSize {
    return CGSizeMake(20,20);
}


+(BOOL)point:(const OTMPoint *)p isFilteredWithMode:(AZTileFilterMode)mode filter:(u_char)filter {
    BOOL draw = YES;
    if (mode == AZTileFilterModeNone) {
        draw = YES;
    } else if (mode == AZTileFilterModeAny) {
        if ((~(p->style) & filter) == 0) {
            draw = NO;
        }
    } else if (mode == AZTileFilterModeAll) {
        if (p->style == filter) {
            draw = NO;
        }
    }

    return draw;
}


+(UIImage *)stampForZoom:(MKZoomScale)zoom hasTree:(BOOL)hastree {
    return [AZTileRenderer stampForZoom:zoom filter:AZTileFilterNone mode:AZTileFilterModeNone hasTree:hastree];
}

+(UIImage *)stampForZoom:(MKZoomScale)zoom filter:(u_char)filter mode:(AZTileFilterMode)mode hasTree:(BOOL)hastree {
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
    
    if (mode == AZTileFilterModeNone) {
        if (!hastree) {
            imageName = [NSString stringWithFormat:@"%@_plot", imageName];
        }
    } else {
        imageName = @"tree_search";
    }
    
    return [UIImage imageNamed:imageName];
}

@end
