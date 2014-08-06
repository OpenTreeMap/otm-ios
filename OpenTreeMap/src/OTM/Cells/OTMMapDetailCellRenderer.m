// This file is part of the OpenTreeMap code.
//
// OpenTreeMap is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// OpenTreeMap is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with OpenTreeMap.  If not, see <http://www.gnu.org/licenses/>.

#import "OTMMapDetailCellRenderer.h"
#import "OTMMapTableViewCell.h"
#import "OTMTreeDictionaryHelper.h"

@implementation OTMMapDetailCellRenderer

-(id)initWithDataKey:(NSString *)datakey {
    self = [super initWithDataKey:datakey];

    if (self) {
        self.cellHeight = kOTMMapTableViewCellHeight;
        self.editCellRenderer = (id)[[OTMEditMapDetailCellRenderer alloc] initWithDetailRenderer:self];
    }

    return self;
}

- (OTMCellSorter *)prepareCell:(NSDictionary *)data inTable:(UITableView *)tableView
{
    OTMMapTableViewCell *detailCell = [tableView dequeueReusableCellWithIdentifier:kOTMMapDetailCellRendererTableCellId];

    if (detailCell == nil) {
        detailCell = [[OTMMapTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                   reuseIdentifier:kOTMMapDetailCellRendererTableCellId];
    }

    CLLocationCoordinate2D center = [OTMTreeDictionaryHelper getCoordinateFromDictionary:data[@"plot"]];

    [detailCell annotateCenter:center];
    detailCell.accessoryType = UITableViewCellAccessoryNone;
    return [[OTMCellSorter alloc] initWithCell:detailCell
                                       sortKey:nil
                                      sortData:nil
                                        height:self.cellHeight
                                 clickCallback:nil];
}

@end


@implementation OTMEditMapDetailCellRenderer

-(id)initWithDetailRenderer:(OTMMapDetailCellRenderer *)mapDetailCellRenderer
{
    self = [super init];
    if (self) {
        renderer = mapDetailCellRenderer;
        self.cellHeight = kOTMMapTableViewCellHeight;
        self.inited = NO;
    }
    return self;
}

- (OTMCellSorter *)prepareCell:(NSDictionary *)data inTable:(UITableView *)tableView
{
    OTMMapTableViewCell *detailCell;

    if (!self.inited) {
        OTMCellSorter *cellContainer = (OTMCellSorter *)[super prepareCell:data inTable:tableView];
        detailCell = (OTMMapTableViewCell *) [cellContainer cell];
        self.inited = YES;
    } else {
        detailCell = [tableView dequeueReusableCellWithIdentifier:kOTMMapDetailCellRendererTableCellId];
    }
    detailCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return [[OTMCellSorter alloc] initWithCell:detailCell
                                       sortKey:nil
                                      sortData:nil
                                        height:self.cellHeight
                                 clickCallback:nil];
}

-(NSDictionary *)updateDictWithValueFromCell:(NSDictionary *)dict {
    return dict;
}

@end
