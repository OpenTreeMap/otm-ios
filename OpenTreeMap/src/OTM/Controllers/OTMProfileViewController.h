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

#import <UIKit/UIKit.h>
#import "OTMUser.h"
#import "OTMPictureTaker.h"
#import "GAITrackedViewController.h"

@interface OTMProfileViewController : GAITrackedViewController<UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate> {
    BOOL loading;
    CGFloat heightOffset;
    double startedTime;
    double delayTime;
}

@property (nonatomic,strong) NSMutableArray *recentActivity;
@property (nonatomic,strong) OTMPictureTaker *pictureTaker;
@property (nonatomic,strong) OTMUser *user;

@property (nonatomic,assign) BOOL didShowLogin;

@property (nonatomic,strong) IBOutlet UIView *pwReqView;
@property (nonatomic,strong) IBOutlet UIButton *switchInstanceButton;
@property (nonatomic,strong) IBOutlet UITableView *tableView;
@property (nonatomic,strong) IBOutlet UIView *loadingView;

@end
