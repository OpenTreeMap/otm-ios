/*
 
 AZPointOffsetOverlayView.h
 
 Created by Justin Walgran on 2/21/12.
 
 License
 =======
 Copyright (c) 2012 Azavea. All rights reserved.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 */

#import <MapKit/MapKit.h>
#import "AZGeoCache.h"
#import "OTMFilterListViewController.h"

/**
 A view for rendering AZPointOffsetOverlay instances on a MapKit map.
 */
@interface AZPointOffsetOverlayView : MKOverlayView {
    NSMutableSet *loading;
    NSMutableSet *loadingFilter;
}

@property (nonatomic,strong) OTMFilters *filters;

@property (nonatomic,strong) AZGeoCache *memoryTileCache;
@property (nonatomic,strong) AZGeoCache *memoryFilterTileCache;
@property (nonatomic,strong) AZGeoCache *memoryPointCache;

@property (nonatomic,strong) UIImage* pointStamp;
@property (nonatomic,assign) CGFloat tileAlpha;

@property (nonatomic,assign) CGSize maximumStampSize;

/**
 The view renders images and caches them. When a tree is added or removed,
 this cache needs to be disrupted so that the image will be rerendered from
 the data source.
 */
- (void)disruptCacheForCoordinate:(CLLocationCoordinate2D)coordinate;

@end