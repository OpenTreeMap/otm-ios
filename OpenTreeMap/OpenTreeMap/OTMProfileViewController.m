//
//  OTMProfileViewController.m
//  OpenTreeMap
//
//  Created by Adam Hinz on 3/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OTMProfileViewController.h"
#import "OTMView.h"

#define kOTMProfileViewControllerSectionInfo 0
#define kOTMProfileViewControllerSectionChangePassword 1
#define kOTMProfileViewControllerSectionChangeProfilePicture 2
#define kOTMProfileViewControllerSectionRecentEdits 3

#define kOTMProfileViewControllerSectionInfoCellIdentifier @"kOTMProfileViewControllerSectionInfoCellIdentifier"
#define kOTMProfileViewControllerSectionChangePasswordCellIdentifier @"kOTMProfileViewControllerSectionChangePasswordCellIdentifier"
#define kOTMProfileViewControllerSectionChangeProfilePictureCellIdentifier @"kOTMProfileViewControllerSectionChangeProfilePictureCellIdentifier"
#define kOTMProfileViewControllerSectionRecentEditsCellIdentifier @"kOTMProfileViewControllerSectionRecentEditsCellIdentifier"

@interface OTMProfileViewController ()

@end

@implementation OTMProfileViewController

@synthesize tableView, user, pictureTaker, recentActivity, loadingView, didShowLogin, pwReqView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (UITableViewCell *)tableView:(UITableView *)tblView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath section] == kOTMProfileViewControllerSectionInfo) {
        return [self tableView:tblView infoCellForRow:[indexPath row]];
    } else if ([indexPath section] == kOTMProfileViewControllerSectionChangePassword) {
        UITableViewCell *cell = [tblView dequeueReusableCellWithIdentifier:kOTMProfileViewControllerSectionChangePasswordCellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                          reuseIdentifier:kOTMProfileViewControllerSectionChangePasswordCellIdentifier];
        }
        
        if ([indexPath row] == 0) {
            cell.textLabel.text = @"Change Password";
        } else {
            cell.textLabel.text = @"Logout";
        }
        
        return cell;
    } else if ([indexPath section] == kOTMProfileViewControllerSectionChangeProfilePicture) {
        UITableViewCell *cell = [tblView dequeueReusableCellWithIdentifier:kOTMProfileViewControllerSectionChangeProfilePictureCellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                          reuseIdentifier:kOTMProfileViewControllerSectionChangeProfilePictureCellIdentifier];
        }
        cell.textLabel.text = @"Change Profile Picture";    
        
        return cell;
    } else {
        UITableViewCell *cell = [tblView dequeueReusableCellWithIdentifier:kOTMProfileViewControllerSectionRecentEditsCellIdentifier];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                          reuseIdentifier:kOTMProfileViewControllerSectionRecentEditsCellIdentifier];
            
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(250,0,44,44)];
            label.backgroundColor = [UIColor clearColor];
            label.textAlignment = UITextAlignmentRight;
            label.textColor = [UIColor blueColor];
            label.font = [UIFont systemFontOfSize:24];
            label.tag = 2012;
            
            [cell addSubview:label];
        }
        
        UILabel *rep = (UILabel *)[cell viewWithTag:2012];
        
        NSDictionary *action = [self.recentActivity objectAtIndex:[indexPath row]];
        cell.textLabel.text = [action objectForKey:@"name"];
        cell.detailTextLabel.text = [action objectForKey:@"created"];
        rep.text = [NSString stringWithFormat:@"+%@",[action valueForKey:@"value"]];
        
        return cell;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tblView infoCellForRow:(NSInteger)row {
   
    NSString *itemTitle = nil;
    NSString *itemValue = nil;
    
    switch (row) {
        case 0:
            itemTitle = @"Username";
            itemValue = self.user.username;
            break;

        case 1:
            itemTitle = @"First Name";
            itemValue = self.user.firstName;
            break;

        case 2:
            itemTitle = @"Last Name";
            itemValue = self.user.lastName;
            break;

        case 3:
            itemTitle = @"Zip Code";
            itemValue = self.user.zipcode;
            break;

        default:
            break;
    }
    
    UITableViewCell *cell = [tblView dequeueReusableCellWithIdentifier:kOTMProfileViewControllerSectionInfoCellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:kOTMProfileViewControllerSectionInfoCellIdentifier];
    }    
    
    cell.textLabel.text = itemTitle;
    cell.detailTextLabel.text = itemValue;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}
        
- (void)tableView:(UITableView *)tblView didSelectRowAtIndexPath:(NSIndexPath *)path {
    if ([path section] == kOTMProfileViewControllerSectionChangePassword) {
        if ([path row] == 0) {
            [self performSegueWithIdentifier:@"ChangePassword" sender:self];
        } else {
            [self setDidShowLogin:NO];
            [[NSNotificationCenter defaultCenter] postNotificationName:kOTMLoginWorkflowLogout
                                                                object:self
                                                              userInfo:nil];
            [self viewWillAppear:YES];
        }
    } else if ([path section] == kOTMProfileViewControllerSectionChangeProfilePicture) {
        [pictureTaker getPictureInViewController:self
                                        callback:^(UIImage *image) 
         {
             if (image) {
                 self.user.photo = image;
                 
                 [[[OTMEnvironment sharedEnvironment] api] setProfilePhoto:user
                                                                  callback:^(id json, NSError *error) 
                  {
                      if (error != nil) {
                          [[[UIAlertView alloc] initWithTitle:@"Error"
                                                      message:@"Could not save photo"
                                                     delegate:nil
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil] show];
                          }
                  }];
             }
         }];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case kOTMProfileViewControllerSectionInfo:
            return 4;
        case kOTMProfileViewControllerSectionChangePassword:
            return 2;
        case kOTMProfileViewControllerSectionChangeProfilePicture:
            return 1;
        case kOTMProfileViewControllerSectionRecentEdits:
            return [self.recentActivity count];
    }
    
    return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (void)viewDidLoad
{
    delayTime = 1.0; // minimum 1.0 second delay time

    [super viewDidLoad];
    [self.loadingView removeFromSuperview];
    [self.tableView addSubview:self.loadingView];
    
    self.loadingView.hidden = YES;

    if (pictureTaker == nil) {
        pictureTaker = [[OTMPictureTaker alloc] init];
    }
    if (self.recentActivity == nil) {
        self.recentActivity = [NSMutableArray array];
    }
    self.navigationItem.title = @"Profile";

    self.tableView.backgroundView = [[OTMView alloc] init];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)showLoginReqView {
    if (self.pwReqView == nil) {
        [[NSBundle mainBundle] loadNibNamed:@"LoginRequiredView"
                                      owner:self
                                    options:nil];
    }
    
    [self.view addSubview:self.pwReqView];
}

- (IBAction)doLogin:(id)sender {
    OTMLoginManager* mgr = [(OTMAppDelegate*)[[UIApplication sharedApplication] delegate] loginManager];
    
    [mgr presentModelLoginInViewController:self.parentViewController callback:^(BOOL success, OTMUser *aUser) {
        if (success) {
            if (self.pwReqView) {
                [self.pwReqView removeFromSuperview];
                self.title = @"Profile";
            }                
            
            self.user = aUser;
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:kOTMProfileViewControllerSectionInfo]
                          withRowAnimation:UITableViewRowAnimationNone];
            
            if ([self.recentActivity count] == 0) {
                [self loadRecentEdits];
            }
        } else {
            [self showLoginReqView];
        }
    }];    
}

- (void)viewWillAppear:(BOOL)animated {
    
    if (!self.didShowLogin) {
        self.didShowLogin = YES;
        OTMLoginManager* mgr = [(OTMAppDelegate*)[[UIApplication sharedApplication] delegate] loginManager];
        
        @synchronized(mgr) {
            if (mgr.runningLogin) {        
                [mgr installAutoLoginFailedCallback:^{
                    [self doLogin:nil];
                }];
            } else {
                [self doLogin:nil];
            }
        }
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (self.loadingView.hidden == YES && scrollView.contentOffset.y > scrollView.contentSize.height - 400) {
        heightOffset = self.loadingView.frame.size.height + 5;

        self.tableView.contentSize = CGSizeMake(self.tableView.contentSize.width,
                                                self.tableView.contentSize.height +
                                                heightOffset);
        
        self.loadingView.frame = CGRectMake(0,
                                            self.tableView.contentSize.height - heightOffset,
                                            320,
                                            40);

        self.loadingView.hidden = NO;
        [self loadRecentEdits];
    }

}

-(void)loadRecentEdits {
    if (loading == YES) {
        return;
    }
    
    loading = YES;
    startedTime = CFAbsoluteTimeGetCurrent();
    [[[OTMEnvironment sharedEnvironment] api] getRecentActionsForUser:self.user
                                                               offset:[self.recentActivity count]
                                                             callback:
     ^(NSArray *json, NSError *error) {
         int rowsBefore = [self.recentActivity count];
         for(NSDictionary *event in json) {
             if ([self.recentActivity indexOfObjectPassingTest:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
                 if ([[obj valueForKey:@"id"] intValue] == [[event valueForKey:@"id"] intValue]) {
                     *stop = YES;
                     return YES;
                 } else {
                     return NO;
                 }
             }] == NSNotFound) {
                 [self.recentActivity addObject:event];
             }
                     
         }

         int rowsAdded = [self.recentActivity count] - rowsBefore;
         
         dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * MAX(0,startedTime + delayTime - CFAbsoluteTimeGetCurrent()));
         dispatch_after(delay, dispatch_get_main_queue(), ^{             
                 [UIView animateWithDuration:.4
                                  animations:
                             ^{
                         self.tableView.contentSize = CGSizeMake(self.tableView.contentSize.width,
                                                                 self.tableView.contentSize.height - heightOffset);
                     }
                 completion:^(BOOL finished) 
                         {
                             NSMutableArray *addedRows = [NSMutableArray array];
                             for(int i=0;i<rowsAdded;i++) {
                                 [addedRows addObject:[NSIndexPath indexPathForRow:i+rowsBefore inSection:kOTMProfileViewControllerSectionRecentEdits]];
                             }

                             // [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:kOTMProfileViewControllerSectionRecentEdits]
                             // withRowAnimation:UITableViewRowAnimationNone
                             //               ];             
                             [self.tableView insertRowsAtIndexPaths:addedRows withRowAnimation:UITableViewRowAnimationNone];
             
                             self.loadingView.hidden = YES;
                         }];
                 loading = NO;
             });
     }];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
