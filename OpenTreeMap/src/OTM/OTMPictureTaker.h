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

#import <Foundation/Foundation.h>

typedef void(^OTMPickerTakerCallback)(UIImage *image);

/**
 * Wrapper class that simplifies the interface required to take
 * pictures
 *
 * Objects with this class are neither reentrant nor threadsafe
 */
@interface OTMPictureTaker : NSObject<UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate> {
    OTMPickerTakerCallback callback;
    UIViewController *targetViewController;
}

-(void)getPictureInViewController:(UIViewController *)vc callback:(OTMPickerTakerCallback)cb;

@end
