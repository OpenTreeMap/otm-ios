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

-(UITableViewCell *)prepareCell:(NSDictionary *)data inTable:(UITableView *)tableView {
    OTMMapTableViewCell *detailCell = [tableView dequeueReusableCellWithIdentifier:kOTMMapDetailCellRendererTableCellId];

    if (detailCell == nil) {
        detailCell = [[OTMMapTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                   reuseIdentifier:kOTMMapDetailCellRendererTableCellId];
    }

    CLLocationCoordinate2D center = [OTMTreeDictionaryHelper getCoordinateFromDictionary:data[@"plot"]];

    [detailCell annotateCenter:center];

    NSDictionary *pendingEditDict = [data objectForKey:@"pending_edits"];
    if ([pendingEditDict objectForKey:self.dataKey]) {
        detailCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        [detailCell setDetailArrowHidden:NO];
    } else {
        detailCell.accessoryType = UITableViewCellAccessoryNone;
    }

    return detailCell;
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

-(UITableViewCell *)prepareCell:(NSDictionary *)data inTable:(UITableView *)tableView {
    OTMMapTableViewCell *detailCell;

    if (!self.inited) {
        detailCell = (OTMMapTableViewCell *)[super prepareCell:data inTable:tableView];

        // The edit cell is the same as the non-edit cell except for the presence of the
        // detail "greater than" arrow.
        [detailCell setDetailArrowHidden:NO];
        self.inited = YES;
    } else {
        detailCell = [tableView dequeueReusableCellWithIdentifier:kOTMMapDetailCellRendererTableCellId];
    }

    return detailCell;
}

-(NSDictionary *)updateDictWithValueFromCell:(NSDictionary *)dict {
    return dict;
}

@end
