//
//  OTMChoicesDetailCellRenderer.h
//  OpenTreeMap
//
//  Created by Adam Hinz on 4/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTMDetailCellRenderer.h"

@interface OTMChoicesDetailCellRenderer : OTMDetailCellRenderer

@property (nonatomic,strong) NSString *label;
@property (nonatomic,strong) NSString *fieldName;
@property (nonatomic,strong) NSArray *fieldChoices;

@end

@interface OTMEditChoicesDetailCellRenderer : OTMEditDetailCellRenderer

-(id)initWithDetailRenderer:(OTMChoicesDetailCellRenderer *)aRenderer;

@property (nonatomic,strong,readonly) NSString *output;

@property (nonatomic,weak) OTMChoicesDetailCellRenderer *renderer;
@property (nonatomic,strong) UITableViewController *controller;

@property (nonatomic,strong) NSDictionary *selected;
@property (nonatomic,strong,readonly) OTMDetailTableViewCell *cell;

@end


