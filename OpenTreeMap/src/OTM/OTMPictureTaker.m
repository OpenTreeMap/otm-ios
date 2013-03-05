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

#import "OTMPictureTaker.h"

@implementation OTMPictureTaker

-(IBAction)showProfilePicturePicker {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Select Image"
                                                                 delegate:self
                                                        cancelButtonTitle:@"Cancel"
                                                   destructiveButtonTitle:@"Photo Album"
                                                        otherButtonTitles:@"Camera",nil];

        UIWindow *mainWindow = [[[UIApplication sharedApplication] delegate] window];
        [actionSheet showInView:mainWindow];
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
    callback = [cb copy];
    targetViewController = vc;

    [self showProfilePicturePicker];
}

@end
