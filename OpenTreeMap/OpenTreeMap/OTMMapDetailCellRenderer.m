/*
 
 OTMMapDetailCellRenderer.m
 
 Created by Justin Walgran on 5/14/12.
 
 License
 =======
 Copyright (c) 2012 Azavea. All rights reserved.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 */

#import "OTMMapDetailCellRenderer.h"
#import "OTMMapTableViewCell.h"

@implementation OTMMapDetailCellRenderer

-(id)initWithDict:(NSDictionary *)dict {
    self = [super initWithDict:dict];
    
    if (self) {
        self.editCellRenderer = [[OTMEditMapDetailCellRenderer alloc] initWithDetailRenderer:self];
        self.cellHeight = kOTMMapTableViewCellHeight;
    }
    
    return self;
}

-(UITableViewCell *)prepareCell:(NSDictionary *)data inTable:(UITableView *)tableView {
    OTMMapTableViewCell *detailCell = [tableView dequeueReusableCellWithIdentifier:kOTMMapDetailCellRendererTableCellId];
    
    if (detailCell == nil) {
        detailCell = [[OTMMapTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                   reuseIdentifier:kOTMMapDetailCellRendererTableCellId];
    } 
    
    [detailCell.mapView setUserInteractionEnabled:NO];
    
    NSDictionary *geometryDict = [data objectForKey:@"geometry"];
    
    float lat = [[geometryDict objectForKey:@"lat"] floatValue];

    float lon;
    if ([geometryDict objectForKey:@"lon"]) {
        lon = [[geometryDict objectForKey:@"lon"] floatValue];
    } else {
        lon = [[geometryDict objectForKey:@"lng"] floatValue];
    }
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(lat, lon);
    
    [detailCell annotateCenter:center];
    
    detailCell.accessoryType = UITableViewCellAccessoryNone;
    
    return detailCell;
}    
@end


@implementation OTMEditMapDetailCellRenderer

-(id)initWithDetailRenderer:(OTMMapDetailCellRenderer *)mapDetailCellRenderer {
    self = [super init];
    if (self) {
        renderer = mapDetailCellRenderer;
        self.cellHeight = kOTMMapTableViewCellHeight;
    }
    return self;
}

-(UITableViewCell *)prepareCell:(NSDictionary *)data inTable:(UITableView *)tableView {
    OTMMapTableViewCell *detailCell = [tableView dequeueReusableCellWithIdentifier:kOTMEditMapDetailCellRendererTableCellId];
    
    if (detailCell == nil) {
        detailCell = [[OTMMapTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                reuseIdentifier:kOTMEditMapDetailCellRendererTableCellId];
    } 
    
    NSDictionary *geometryDict = [data objectForKey:@"geometry"];
    
    float lat = [[geometryDict objectForKey:@"lat"] floatValue];
    
    float lon;
    if ([geometryDict objectForKey:@"lon"]) {
        lon = [[geometryDict objectForKey:@"lon"] floatValue];
    } else {
        lon = [[geometryDict objectForKey:@"lng"] floatValue];
    }
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(lat, lon);
    
    [detailCell annotateCenter:center];
    
    detailCell.accessoryType = UITableViewCellAccessoryNone;
    
    return detailCell;
}   

-(NSDictionary *)updateDictWithValueFromCell:(NSDictionary *)dict {
    return dict;
}

@end