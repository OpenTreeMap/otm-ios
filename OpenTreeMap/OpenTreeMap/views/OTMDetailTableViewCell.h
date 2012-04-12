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

#import <UIKit/UIKit.h>

@protocol OTMDetailTableViewCellDelegate <NSObject>

-(void)tableViewCell:(UITableViewCell *)tblViewCell updatedToValue:(NSString *)v;

@end

@interface OTMDetailTableViewCell : UITableViewCell<UITextFieldDelegate>

@property (nonatomic, strong) UILabel *fieldLabel;
@property (nonatomic, strong) UILabel *fieldValue;
@property (nonatomic, strong) UITextField *editFieldValue;
@property (nonatomic, assign) BOOL allowsEditing;

@property (nonatomic, weak) id<UITextFieldDelegate> tfDelegate;
@property (nonatomic, weak) id<OTMDetailTableViewCellDelegate> delegate;

@end
