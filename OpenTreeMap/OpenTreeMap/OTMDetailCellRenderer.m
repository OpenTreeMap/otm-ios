//
//  OTMDetailCellRenderer.m
//  OpenTreeMap
//
//  Created by Adam Hinz on 4/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OTMDetailCellRenderer.h"
#import "OTMFormatters.h"

@implementation OTMDetailCellRenderer

@synthesize dataKey, editCellRenderer, newCellBlock, clickCallback, cellHeight;

+(OTMDetailCellRenderer *)cellRendererFromDict:(NSDictionary *)dict {
    NSString *clazz = [dict objectForKey:@"class"];
           
    OTMDetailCellRenderer *renderer;
    if (clazz == nil) {
        renderer = [[kOTMDefaultDetailRenderer alloc] initWithDict:dict];
    } else {
        renderer = [[NSClassFromString(clazz) alloc] initWithDict:dict];
    }
    
    return renderer;
}

-(id)init {
    self = [super init];
    
    if (self) {
        self.cellHeight = 44;
    }
    
    return self;
}

-(id)initWithDict:(NSDictionary *)dict {
    self = [self init];
    
    if (self) {
        dataKey = [dict objectForKey:@"key"];
        
        id ro = [dict valueForKey:@"readonly"];
        
        if (ro == nil || [ro boolValue] == NO) {
            self.editCellRenderer = [OTMLabelEditDetailCellRenderer editCellRendererFromDict:dict];
        }        
    }
    
    return self;
}

-(UITableViewCell *)prepareCell:(NSDictionary *)data inTable:(UITableView *)tableView {
    ABSTRACT_METHOD_BODY
}

@end

#define kOTMLabelDetailCellRendererCellId @"kOTMLabelDetailCellRendererCellId"

@implementation OTMLabelDetailCellRenderer

@synthesize label, formatStr;

-(id)initWithDict:(NSDictionary *)dict {
    self = [super initWithDict:dict];
    
    if (self) {
        label = [dict objectForKey:@"label"];
        formatStr = [dict objectForKey:@"format"];
    }
    
    return self;
}

-(UITableViewCell *)prepareCell:(NSDictionary *)data inTable:(UITableView *)tableView {
    OTMDetailTableViewCell *detailcell = [tableView dequeueReusableCellWithIdentifier:kOTMLabelDetailCellRendererCellId];
    
    if (detailcell == nil) {
        detailcell = [[OTMDetailTableViewCell alloc] initWithStyle:UITableViewCellStyleValue2
                                                   reuseIdentifier:kOTMLabelDetailCellRendererCellId];
    } 
    
    id value = [data decodeKey:self.dataKey];
    
    detailcell.fieldLabel.text = self.label;
    detailcell.fieldValue.text = [OTMFormatters fmtObject:value withKey:self.formatStr];
    
    return detailcell;
}

@end

@implementation OTMEditDetailCellRenderer : OTMDetailCellRenderer

-(id)initWithDict:(NSDictionary *)dict {
    self = [super init];
    
    if (self) {
        self.dataKey = [dict objectForKey:@"key"];
    }

    return self; 
}

-(NSDictionary *)updateDictWithValueFromCell:(NSDictionary *)dict {
    ABSTRACT_METHOD_BODY
}

+(OTMEditDetailCellRenderer *)editCellRendererFromDict:(NSDictionary *)dict {
    NSString *clazz = [dict objectForKey:@"editClass"];
    
    OTMEditDetailCellRenderer *renderer;
    if (clazz == nil) {
        renderer = [[kOTMDefaultEditDetailRenderer alloc] initWithDict:dict];
    } else {
        renderer = [[NSClassFromString(clazz) alloc] initWithDict:dict];
    }
    
    return renderer;
}

@end

@implementation OTMLabelEditDetailCellRenderer

@synthesize label, updatedString;

-(id)initWithDict:(NSDictionary *)dict {
    self = [super initWithDict:dict];
    
    if (self) {
        label = [dict objectForKey:@"label"];
    }
    
    return self;
}

-(void)tableViewCell:(UITableViewCell *)tblViewCell textField:(UITextField *)field updatedToValue:(NSString *)v {
    self.updatedString = v;
}

-(NSDictionary *)updateDictWithValueFromCell:(NSDictionary *)dict {
    if (updatedString) {
        [dict setObject:updatedString forEncodedKey:self.dataKey];
        updatedString = nil;
    }
    
    return dict;
}

#define kOTMLabelDetailEditCellRendererCellId @"kOTMLabelDetailEditCellRendererCellId"

-(UITableViewCell *)prepareCell:(NSDictionary *)data inTable:(UITableView *)tableView {
    OTMDetailTableViewCell *detailcell = [tableView dequeueReusableCellWithIdentifier:kOTMLabelDetailEditCellRendererCellId];
    
    if (detailcell == nil) {
        detailcell = [[OTMDetailTableViewCell alloc] initWithStyle:UITableViewCellStyleValue2
                                                   reuseIdentifier:kOTMLabelDetailEditCellRendererCellId];
    } 
    
    detailcell.delegate = self;
    detailcell.editFieldValue.hidden = NO;
    detailcell.fieldValue.hidden = YES;
    
    id value = [data decodeKey:self.dataKey];
    
    detailcell.editFieldValue.text = [OTMFormatters fmtObject:value withKey:@""];
    detailcell.fieldLabel.text = self.label;
    
    return detailcell;
}

@end

@implementation OTMDBHEditDetailCellRenderer

@synthesize cell;

-(id)initWithDict:(NSDictionary *)dict {
    self = [super initWithDict:dict];
    
    if (self) {
        cell = [OTMDBHTableViewCell loadFromNib];
        cell.delegate = self;
        self.cellHeight = cell.frame.size.height;
    }
    
    return self;
}

-(void)tableViewCell:(UITableViewCell *)tblViewCell textField:(UITextField *)field updatedToValue:(NSString *)v {
    
    if (field == self.cell.circumferenceTextField) {
        CGFloat circ = [v floatValue];
        NSString *diam = [NSString stringWithFormat:@"%0.0f",circ / M_PI];
        
        self.cell.diameterTextField.text = diam;
    } else {
        CGFloat diam = [v floatValue];
        NSString *circ = [NSString stringWithFormat:@"%0.0f",diam * M_PI];
        
        self.cell.circumferenceTextField.text = circ;        
    }
}

-(NSDictionary *)updateDictWithValueFromCell:(NSDictionary *)dict {
    NSString *newDBH = self.cell.diameterTextField.text;
    if (newDBH && [newDBH length] > 0) {
        [dict setObject:self.cell.diameterTextField.text
          forEncodedKey:self.dataKey];
    }
    
    return dict;
}

#define OTMLabelDetailEditCellRendererCellId @"kOTMLabelDetailEditCellRendererCellId"

-(UITableViewCell *)prepareCell:(NSDictionary *)data inTable:(UITableView *)tableView {
    self.cell.diameterTextField.text = [[data decodeKey:self.dataKey] description];
    [self tableViewCell:nil
              textField:self.cell.diameterTextField
         updatedToValue:self.cell.diameterTextField.text];
    
    return cell;
}

@end

@implementation OTMStaticClickCellRenderer

#define kOTMDetailEditSpeciesCellRendererCellId @"kOTMDetailEditSpeciesCellRendererCellId"

@synthesize name, data, defaultName;

-(id)initWithKey:(NSString *)key clickCallback:(Function1v)aCallback {
    return [self initWithName:nil key:key clickCallback:aCallback];
}

-(id)initWithName:(NSString *)aName key:(NSString *)key clickCallback:(Function1v)aCallback {
    self = [super init];
    
    if (self) {
        self.dataKey = key;
        data = nil;
        name = aName;
        
        self.clickCallback = aCallback;
    }
    
    return self;
}

-(UITableViewCell *)prepareCell:(NSDictionary *)renderData inTable:(UITableView *)tableView {
    UITableViewCell *detailcell = [tableView dequeueReusableCellWithIdentifier:kOTMDetailEditSpeciesCellRendererCellId];
    
    if (detailcell == nil) {
        detailcell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                            reuseIdentifier:kOTMDetailEditSpeciesCellRendererCellId];
    } 
    
    if (name == nil) {
        NSString *val = [renderData decodeKey:self.dataKey];
        
        if (val == nil || [val length] == 0) {
            val = self.defaultName;
        }
        
        detailcell.textLabel.text = val;
    } else {
        detailcell.textLabel.text = name;        
    }
    
    detailcell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
    return detailcell;
}

-(NSDictionary *)updateDictWithValueFromCell:(NSDictionary *)dict {
    return dict;
}


@end