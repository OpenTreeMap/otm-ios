//                                                                                                                
// Copyright (c) 2012 Azavea                                                                                
//                                                                                                                
// Permission is hereby granted, free of charge, to any person obtaining a copy                                   
// of this software and associated documentation files (the "Software"), to                                       
// deal in the Software without restriction, including without limitation the                                     
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or                                    
//  sell copies of the Software, and to permit persons to whom the Software is                                    
// furnished to do so, subject to the following conditions:                                                       
//                                                                                                                
// The above copyright notice and this permission notice shall be included in                                     
// all copies or substantial portions of the Software.                                                            
//                                                                                                                
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR                                     
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,                                       
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE                                    
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER                                         
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,                                  
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN                                      
// THE SOFTWARE.                                                                                                  
//  

#import "OTMDetailTableViewCell.h"
#import "OTMFormatters.h"

@implementation OTMDetailTableViewCell

@synthesize fieldLabel, fieldValue, editFieldValue, tfDelegate, allowsEditing, delegate, formatKey;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {        
        CGRect frame = self.frame;
        
        CGRect leftFrame = CGRectMake(25, 0, 
                                      CGRectGetMidX(frame),
                                      frame.size.height);
        CGRect rightFrame = CGRectMake(CGRectGetMidX(frame), 0,
                                       CGRectGetMidX(frame),
                                       frame.size.height);
        
        CGRect inputFrame = CGRectInset(rightFrame, 0, 10);
        
        self.fieldLabel = [self labelWithFrame:leftFrame];
        self.fieldValue = [self labelWithFrame:rightFrame];
        
        self.editFieldValue = [[UITextField alloc] initWithFrame:inputFrame];
        self.editFieldValue.delegate = self;
        
        [self.fieldLabel setTextColor:[UIColor grayColor]];
        
        [self addSubview:self.fieldValue];
        [self addSubview:self.fieldLabel];
        [self addSubview:self.editFieldValue];
        
        editFieldValue.hidden = YES;
    }
    return self;
}

- (UILabel*)labelWithFrame:(CGRect)rect {
    UILabel* label = [[UILabel alloc] initWithFrame:rect];
    label.textAlignment = UITextAlignmentLeft;
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont systemFontOfSize:15];
    
    return label;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    if (allowsEditing) {        
        if (editing == NO) { // Transition from editing to view
            if (self.formatKey != nil) {
                fieldValue.text = [OTMFormatters fmtObject:self.editFieldValue.text
                                                   withKey:self.formatKey];
            } else {
                fieldValue.text = self.editFieldValue.text;
            }
        }
        
        editFieldValue.hidden = !editing;
        fieldValue.hidden = editing;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    // [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark Text Field Delegates

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [tfDelegate textFieldDidBeginEditing:textField];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [tfDelegate textFieldDidEndEditing:textField];
    [delegate tableViewCell:self updatedToValue:textField.text];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    return [tfDelegate textFieldShouldReturn:textField];
}

@end
