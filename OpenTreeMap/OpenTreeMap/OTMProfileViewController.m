//
//  OTMProfileViewController.m
//  OpenTreeMap
//
//  Created by Adam Hinz on 3/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OTMProfileViewController.h"

#define kOTMProfileViewControllerSectionInfo 0
#define kOTMProfileViewControllerSectionChangePassword 1
#define kOTMProfileViewControllerSectionChangeProfilePicture 2
#define kOTMProfileViewControllerSectionRecentEdits 3

#define kOTMProfileViewControllerSectionInfoCellIdentifier @"kOTMProfileViewControllerSectionInfoCellIdentifier"
#define kOTMProfileViewControllerSectionChangePasswordCellIdentifier @"kOTMProfileViewControllerSectionChangePasswordCellIdentifier"
#define kOTMProfileViewControllerSectionChangeProfilePictureCellIdentifier @"kOTMProfileViewControllerSectionChangeProfilePictureCellIdentifier"

@interface OTMProfileViewController ()

@end

@implementation OTMProfileViewController

@synthesize tableView, user;

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
        
        cell.textLabel.text = @"Change Password";
        
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
        return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:@"blahr"];
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
        [self performSegueWithIdentifier:@"ChangePassword" sender:self];
    } else if ([path section] == kOTMProfileViewControllerSectionChangeProfilePicture) {
        
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case kOTMProfileViewControllerSectionInfo:
            return 4;
        case kOTMProfileViewControllerSectionChangePassword:
        case kOTMProfileViewControllerSectionChangeProfilePicture:
            return 1;
        case kOTMProfileViewControllerSectionRecentEdits:
            return 0;
    }
    
    return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)viewWillAppear:(BOOL)animated {
    OTMLoginManager* mgr = [(OTMAppDelegate*)[[UIApplication sharedApplication] delegate] loginManager];

    [mgr presentModelLoginInViewController:self.parentViewController callback:^(BOOL success, OTMUser *aUser) {
        if (success) {
            self.user = aUser;
            [self.tableView reloadData];
        }
    }];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
