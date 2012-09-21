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
#import "OTMFormatters.h"

@implementation OTMDetailTableViewCell

@synthesize fieldLabel, fieldValue, editFieldValue, pendImageView, tfDelegate, allowsEditing, delegate, formatKey;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {        
        CGRect frame = self.frame;
        
        CGRect leftFrame = CGRectMake(25, 0, 
                                      CGRectGetMidX(frame),
                                      frame.size.height);
        CGRect rightFrame = CGRectMake(CGRectGetMidX(frame), 0,
                                       CGRectGetMidX(frame) - 25,
                                       frame.size.height);
        
        CGRect inputFrame = CGRectMake(195, 6,
                                       98,
                                       31);       
        
        self.fieldLabel = [self labelWithFrame:leftFrame];
        self.fieldValue = [self labelWithFrame:rightFrame];
        
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

- (UILabel*)labelWithFrame:(CGRect)rect {
    UILabel* label = [[UILabel alloc] initWithFrame:rect];
    label.textAlignment = UITextAlignmentLeft;
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont systemFontOfSize:15];
    
    return label;
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
    [delegate tableViewCell:self textField:textField updatedToValue:textField.text];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    return [tfDelegate textFieldShouldReturn:textField];
}

@end
