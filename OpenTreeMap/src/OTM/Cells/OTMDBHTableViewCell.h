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

#import <UIKit/UIKit.h>
#import "OTMDetailTableViewCell.h"

@interface OTMDBHTableViewCell : UITableViewCell

+(OTMDBHTableViewCell *)loadFromNib;

@property (nonatomic,strong) IBOutlet UITextField *circumferenceTextField;
@property (nonatomic,strong) IBOutlet UITextField *diameterTextField;

@property (nonatomic,strong) IBOutlet UILabel *circumferenceLabel;
@property (nonatomic,strong) IBOutlet UILabel *diameterLabel;

@property (nonatomic,weak) id<UITextFieldDelegate> tfDelegate;
@property (nonatomic,weak) id<OTMDetailTableViewCellDelegate> delegate;

@end
