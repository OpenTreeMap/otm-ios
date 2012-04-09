/*
 
 OTMAddTreeViewController.h
 
 Created by Justin Walgran on 4/9/12.
 
 License
 =======
 Copyright (c) 2012 Azavea. All rights reserved.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
 documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
 rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit
 persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
 Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
 WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
 OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 */

#import <UIKit/UIKit.h>

@interface OTMAddTreeViewController : UIViewController <MKMapViewDelegate, UIGestureRecognizerDelegate> {
    IBOutlet MKMapView *mv;
}

@property (nonatomic,strong) IBOutlet UILabel *messageLabel;
@property (nonatomic,strong) IBOutlet UIButton *addAnotherButton;
@property (nonatomic,strong) IBOutlet UIButton *addDetailButton;
@property (nonatomic,strong) IBOutlet UIButton *cleanMapButton;


@property (nonatomic,strong) MKPointAnnotation* activeTreeAnnotation;

- (IBAction)addAnother:(id)sender;
- (IBAction)addDetail:(id)sender;
- (IBAction)cleanMap:(id)sender;

@end
