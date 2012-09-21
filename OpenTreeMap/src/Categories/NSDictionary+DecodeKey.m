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

#import "NSDictionary+DecodeKey.h"

@implementation NSDictionary (DecodeKey)

- (NSString*)decodeKey:(NSString *)keystr {
    NSArray* keylist = [keystr componentsSeparatedByString:@"."];
    
    id thing = self;
    for(NSString* key in keylist) {
        if ([thing respondsToSelector:@selector(objectForKey:)]) {
            thing = [thing objectForKey:key];
        } else {
            return nil;
        }
        
        if (thing == nil || thing == [NSNull null]) {
            return nil;
        }
    }
    
    return thing;
}

- (void)setObject:(id)obj forEncodedKey:(NSString *)keystr {
    NSArray* keylist = [keystr componentsSeparatedByString:@"."];
    
    id thing = self;
    for(int i=0;i<[keylist count] - 1;i++) {
        id key = [keylist objectAtIndex:i];
        if ([thing respondsToSelector:@selector(objectForKey:)]) {
            id aThing = [thing objectForKey:key];
            
            if (aThing == [NSNull null]) {
                aThing = [NSMutableDictionary dictionary];
                [thing setObject:aThing forKey:key];
            }
            
            thing = aThing;
        }
    }    
    
    [thing setObject:obj forKey:[keylist lastObject]];
}

@end
