//
//  OTMJSONResponse.m
//  OpenTreeMap
//
//  Created by Adam Hinz on 2/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OTMJSONResponse.h"
#import "Three20Network/Three20Network.h"

@implementation OTMJSONResponse

@synthesize json;

-(NSError*)request:(TTURLRequest*)request processResponse:(NSHTTPURLResponse *)response data:(id)data {
    NSError* error = nil;
    id jsonp = [NSJSONSerialization JSONObjectWithData:data 
                                              options:0
                                                error:&error];    
    
    self.json = jsonp;
    return error;
}

@end
