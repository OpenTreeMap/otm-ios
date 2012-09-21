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


