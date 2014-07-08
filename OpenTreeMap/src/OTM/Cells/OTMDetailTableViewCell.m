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

#import "OTMDetailTableViewCell.h"
#import "OTMFormatter.h"

@implementation OTMDetailTableViewCell

@synthesize fieldLabel, fieldValue, editFieldValue, pendImageView, tfDelegate, allowsEditing, delegate, formatKey;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        CGRect frame = self.frame;

        CGRect nameFrame = CGRectMake(14, 0,
                                      frame.size.width - 14,
                                      frame.size.height / 2);
        CGRect valueFrame = CGRectMake(14, frame.size.height/2 - 2,
                                       frame.size.width - 14,
                                       frame.size.height / 2);

        CGRect inputFrame = CGRectMake(195, 6,
                                       98,
                                       31);

        CGRect unitFrame = CGRectMake(297, 6,
                                       21,
                                       31);

        self.fieldLabel = [self labelWithFrame:nameFrame];
        self.fieldValue = [self labelWithFrame:valueFrame];
        self.unitLabel = [self labelWithFrame:unitFrame];
        [self.unitLabel setTextColor:[UIColor grayColor]];

        self.editFieldValue = [[UITextField alloc] initWithFrame:inputFrame];
        self.editFieldValue.textAlignment = UITextAlignmentRight;
        self.editFieldValue.delegate = self;
        self.editFieldValue.borderStyle = UITextBorderStyleRoundedRect;

        [self.fieldLabel setTextColor:[UIColor grayColor]];

        self.pendImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"pend"]];
        self.pendImageView.frame = CGRectMake(self.frame.size.width - pendImageView.frame.size.width- 20, self.frame.origin.y + 15, pendImageView.frame.size.width, pendImageView.frame.size.height);

        [self addSubview:self.fieldValue];
        [self addSubview:self.fieldLabel];
        [self addSubview:self.editFieldValue];
        [self addSubview:self.pendImageView];
        [self addSubview:self.unitLabel];

        pendImageView.hidden = YES;
        editFieldValue.hidden = YES;
    }
    return self;
}

- (UIKeyboardType)keyboardType {
    return self.editFieldValue.keyboardType;
}

- (void)setKeyboardType:(UIKeyboardType)t {
    self.editFieldValue.keyboardType = t;
}

-(NSString*)formatHumanReadableDateStringFromString:(NSString *)dateString
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YYYY-MM-dd"];
    NSDate *newDate=[dateFormatter dateFromString:dateString];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    return [dateFormatter stringFromDate:newDate];
}

-(NSString*)formatHumanReadableDateStringFromDate:(NSDate *)date
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    return [dateFormatter stringFromDate:date];
}

-(void)setDatePickerInput
{
    _picker = [[UIDatePicker alloc] init];
    _picker.datePickerMode = UIDatePickerModeDate;
    self.editFieldValue.inputView = _picker;
    CGRect frame = CGRectMake(171, 6, 122, 31);
    [self.editFieldValue setFrame:frame];
    [_picker addTarget:self action:@selector(updateTextFieldWithDate:) forControlEvents:UIControlEventValueChanged];
}

- (UILabel*)labelWithFrame:(CGRect)rect {
    UILabel* label = [[UILabel alloc] initWithFrame:rect];
    label.textAlignment = UITextAlignmentLeft;
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont systemFontOfSize:15];

    return label;
}
-(void)updateTextFieldWithDate:(id)sender {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YYYY-MM-dd"];
    NSString *updateText = [dateFormatter stringFromDate:_picker.date];
    self.editFieldValue.text = [self formatHumanReadableDateStringFromString:updateText];
    [delegate tableViewCell:self textField:self.editFieldValue updatedToValue:updateText];
}

#pragma mark Text Field Delegates

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {

    NSString *newText = [textField.text stringByReplacingCharactersInRange:range
                                                                withString:string];

    return textField.keyboardType != UIKeyboardTypeDecimalPad || [[newText componentsSeparatedByString:@"."] count] <= 2;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [tfDelegate textFieldDidBeginEditing:textField];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [tfDelegate textFieldDidEndEditing:textField];
    if (_picker == nil) {
        [delegate tableViewCell:self textField:textField updatedToValue:textField.text];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    return [tfDelegate textFieldShouldReturn:textField];
}

@end
