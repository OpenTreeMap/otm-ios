//                                                                                                                
// Copyright (c) 2012 Azavea                                                                                
//                                                                                                                
// Permission is hereby granted, free of charge, to any person obtaining a copy                                   
// of this software and associated documentation files (the "Software"), to                                       
// deal in the Software without restriction, including without limitation the                                     
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or                                    
//  sell copies of the Software, and to permit persons to whom the Software is                                    
// furnished to do so, subject to the following conditions:                                                       
//                                                                                                                
// The above copyright notice and this permission notice shall be included in                                     
// all copies or substantial portions of the Software.                                                            
//                                                                                                                
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR                                     
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,                                       
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE                                    
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER                                         
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,                                  
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN                                      
// THE SOFTWARE.                                                                                                  
//    

#import "OTMDetailSliderview.h"

@implementation OTMDetailSliderview

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self loadTheme];
    }
    
    return self;
}

-(id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self loadTheme];
    }
    
    return self;
}

-(void)loadTheme {
    fadeAtBottom = NO;
}

- (void)drawRect:(CGRect)rect
{    
    float pct = .90;   
    float height = self.frame.size.height;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    /// Main Gradient
    float color[] = { pct, pct, pct, 1.0 };
    CGColorRef startColor = [[UIColor whiteColor] CGColor];
    CGColorRef endColor = CGColorCreate(colorSpace, color);

    float locations[] = {0.0, 1.0};
    const void* colors[] = { startColor, endColor };
    CFArrayRef colorArray = CFArrayCreate(NULL, colors, 2, NULL);
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace,
                                                        colorArray, 
                                                        locations);
        
    CGFloat fadeOffset = fadeAtBottom ? 0 : 15;
    CGRect gframe = CGRectMake(0, fadeOffset, self.frame.size.width, height - 15);
    
    CGContextSetFillColorWithColor(context, [[self backgroundColor] CGColor]);
    CGContextFillRect(context, gframe);    
    
    CGContextSaveGState(context);
    CGContextAddRect(context,
                     gframe);
    CGContextClip(context);
    CGContextDrawLinearGradient(context, gradient, 
                                CGPointMake(CGRectGetMidX(gframe), fadeOffset),
                                CGPointMake(CGRectGetMidX(gframe), gframe.size.height + fadeOffset),
                                0);
    CFRelease(colorArray);
    CGColorRelease(endColor);
    
    CGContextRestoreGState(context);
    
    pct = .69;
    float color1[] = { 1.0f, 1.0f, 1.0f, 0.0f };
    startColor = CGColorCreate(colorSpace, color1);
    
    float color2[] = { pct, pct, pct, 1.0 };    
    endColor = CGColorCreate(colorSpace, color2);
    
    const void* colors2[] = { 
        fadeAtBottom ? endColor : startColor, 
        fadeAtBottom ? startColor : endColor };
    
    colorArray = CFArrayCreate(NULL, colors2, 2, NULL);
    gradient = CGGradientCreateWithColors(colorSpace,
                                          colorArray, 
                                          locations);
    
    CGFloat topOffset = fadeAtBottom ? self.frame.size.height - 15 : 0;
    gframe = CGRectMake(0, topOffset, self.frame.size.width, 15);
    
    CGContextSaveGState(context);
    
    CGFloat fadeY = fadeAtBottom ? self.frame.size.height : 15;
    
    CGContextBeginTransparencyLayer(context, NULL);
    [[UIColor clearColor] setFill];
    CGContextFillRect(context,gframe);

    CGContextAddRect(context,
                     gframe);
    CGContextClip(context);
    CGContextDrawLinearGradient(context, gradient, 
                                CGPointMake(CGRectGetMidX(gframe), gframe.origin.y),
                                CGPointMake(CGRectGetMidX(gframe), fadeY),
                                0);    
    
    CGContextEndTransparencyLayer(context);
    CGContextRestoreGState(context);
                     
    CFRelease(colorArray);
    CGColorRelease(startColor);
    CGColorRelease(endColor);
    CGColorSpaceRelease(colorSpace);
}

@end
