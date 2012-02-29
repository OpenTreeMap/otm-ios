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

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    float pct = .90;   
    float height = 10;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [[self backgroundColor] CGColor]);
    CGContextFillRect(context, self.frame);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    float color[] = { pct, pct, pct, 1.0 };
    CGColorRef startColor = CGColorCreate(colorSpace, color);
    CGColorRef endColor = [[self backgroundColor] CGColor];

    float locations[] = {0.0, 1.0};
    const void* colors[] = { startColor, endColor };
    CFArrayRef colorArray = CFArrayCreate(NULL, colors, 2, NULL);
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace,
                                                        colorArray, 
                                                        locations);
    
    CGRect gframe = CGRectMake(0, 0, self.frame.size.width, height);
    
    CGContextSaveGState(context);
    CGContextAddRect(context,
                     gframe);
    CGContextClip(context);
    CGContextDrawLinearGradient(context, gradient, 
                                CGPointMake(CGRectGetMidX(gframe), 0),
                                CGPointMake(CGRectGetMidX(gframe), gframe.size.height),
                                0);
    CGContextRestoreGState(context);
    
    CGContextSetStrokeColorWithColor(context, [[UIColor colorWithWhite:0.50 alpha:1.0] CGColor]);    
    CGContextMoveToPoint(context, 0, 0.5);
    CGContextAddLineToPoint(context, self.frame.size.width, 0.5);
    CGContextStrokePath(context);
                     
    CFRelease(colorArray);
    CGColorRelease(startColor);
    CGColorSpaceRelease(colorSpace);
}

@end
