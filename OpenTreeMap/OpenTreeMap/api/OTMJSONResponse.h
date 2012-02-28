//
//  OTMJSONResponse.h
//  OpenTreeMap
//
//  Created by Adam Hinz on 2/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Three20Network/Three20Network.h"

@interface OTMJSONResponse : NSObject<TTURLResponse>

@property (nonatomic,strong) id json;

@end
