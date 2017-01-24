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

#import "OTMDBHTableViewCell.h"

@interface OTMDummyDelegate : NSObject
@property (nonatomic,strong) UITableViewCell *acell;
@end

@implementation OTMDummyDelegate
@synthesize acell;
@end

@implementation OTMDBHTableViewCell

@synthesize circumferenceTextField, diameterTextField,
    circumferenceUnitLabel, diameterUnitLabel,
    tfDelegate, delegate;

+(OTMDBHTableViewCell *)loadFromNib {
    OTMDummyDelegate *dummy = [[OTMDummyDelegate alloc] init];
    [[NSBundle mainBundle] loadNibNamed:@"OTMDBHTableViewCell"
                                  owner:dummy
                                options:nil];
    OTMDBHTableViewCell *cell = (OTMDBHTableViewCell *)dummy.acell;

    cell.circumferenceTextField.keyboardType = UIKeyboardTypeDecimalPad;
    cell.diameterTextField.keyboardType = UIKeyboardTypeDecimalPad;

    OTMFormatter *dbhFormat = [[OTMEnvironment sharedEnvironment] dbhFormat];
    NSString *unit = [dbhFormat label];

    cell.diameterUnitLabel.text = unit;
    cell.circumferenceUnitLabel.text = unit;

    return cell;
}

#pragma mark Text Field Delegates

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {

    NSString *newText = [textField.text stringByReplacingCharactersInRange:range
                                                                withString:string];

    if ([[newText componentsSeparatedByString:@"."] count] > 2) {
        return NO;
    } else {
        [delegate tableViewCell:self textField:textField updatedToValue:newText];

        return YES;
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [tfDelegate textFieldDidBeginEditing:textField];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [tfDelegate textFieldDidEndEditing:textField];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    return [tfDelegate textFieldShouldReturn:textField];
}

@end
