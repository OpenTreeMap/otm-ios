//
//  OTMDBHTableViewCell.m
//  OpenTreeMap
//
//  Created by Adam Hinz on 4/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OTMDBHTableViewCell.h"

@interface OTMDummyDelegate : NSObject 
@property (nonatomic,strong) UITableViewCell *acell;
@end
@implementation OTMDummyDelegate
@synthesize acell;
@end

@implementation OTMDBHTableViewCell

@synthesize circumferenceTextField, diameterTextField, tfDelegate, delegate;

+(OTMDBHTableViewCell *)loadFromNib {
    OTMDummyDelegate *dummy = [[OTMDummyDelegate alloc] init];
    [[NSBundle mainBundle] loadNibNamed:@"OTMDBHTableViewCell"
                                  owner:dummy
                                options:nil];
    OTMDBHTableViewCell *cell = (OTMDBHTableViewCell *)dummy.acell;

    cell.circumferenceTextField.keyboardType = UIKeyboardTypeDecimalPad;
    cell.diameterTextField.keyboardType = UIKeyboardTypeDecimalPad;

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
