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

#import "OTMPictureTaker.h"

@implementation OTMPictureTaker

-(IBAction)showProfilePicturePicker:(id)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Select Image"
                                                                 delegate:self
                                                        cancelButtonTitle:@"Cancel"
                                                   destructiveButtonTitle:@"Photo Album"
                                                        otherButtonTitles:@"Camera",nil];
        
        [actionSheet showInView:targetViewController.view];
    } else {
        [self showAlbumPicker];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self showAlbumPicker];
    } else if (buttonIndex == 1) {
        [self showCameraPicker];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    UIImage *selectedImage = [info objectForKey:UIImagePickerControllerEditedImage];
    if (selectedImage == nil) {
        selectedImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    }
    if (callback != nil) {
        callback(selectedImage);
    }    
    [targetViewController dismissModalViewControllerAnimated:YES];
}

- (void)showAlbumPicker {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    [targetViewController presentViewController:picker
                                       animated:YES
                                     completion:^{}];   
}

- (void)showCameraPicker {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    [targetViewController presentViewController:picker
                                       animated:YES
                                     completion:^{}];   
}

-(void)getPictureInViewController:(UIViewController *)vc callback:(OTMPickerTakerCallback)cb {
    callback = cb;
    targetViewController = vc;
}

@end
