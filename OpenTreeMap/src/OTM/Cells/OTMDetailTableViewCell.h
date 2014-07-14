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
#import "AZPastelessTextField.h"

@protocol OTMDetailTableViewCellDelegate <NSObject>

-(void)tableViewCell:(UITableViewCell *)tblViewCell textField:(UITextField*)textField updatedToValue:(NSString *)v;

@end

@interface OTMDetailTableViewCell : UITableViewCell<UITextFieldDelegate>

@property (nonatomic, strong) UILabel *fieldLabel;
@property (nonatomic, strong) UILabel *fieldValue;
@property (nonatomic, strong) UILabel *unitLabel;
@property (nonatomic, strong) AZPastelessTextField *editFieldValue;
@property (nonatomic, strong) UIImageView *pendImageView;
@property (nonatomic, assign) BOOL allowsEditing;
@property (nonatomic, assign) UIKeyboardType keyboardType;
@property (nonatomic, copy) NSString *formatKey;
@property (nonatomic, strong) UIDatePicker *picker;

@property (nonatomic, weak) id<UITextFieldDelegate> tfDelegate;
@property (nonatomic, weak) id<OTMDetailTableViewCellDelegate> delegate;

-(void)setDatePickerInput;
-(void)setDatePickerInputWithInitialDate:(NSDate *)initDate;

-(NSString*)formatHumanReadableDateStringFromString:(NSString*)dateString;
-(NSString*)formatHumanReadableDateStringFromDate:(NSDate*)date;

@end
