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

#import "OTMInappropriateContentMailViewController.h"

@interface OTMInappropriateContentMailViewController ()

@end

@implementation OTMInappropriateContentMailViewController

- (id)initWithPhotoDictionary:(NSDictionary *)photo
{
    NSString *photoDetails = [NSString stringWithFormat:@"Instance: %@\nTree ID: %@\nPhoto ID: %@",
                                  [[OTMEnvironment sharedEnvironment] instance],
                                  [photo objectForKey:@"tree"],
                                  [photo objectForKey:@"id"]];

    return [self initWithDetails:photoDetails];
}

- (id)initWithDetails:(NSString *)details
{
    self = [super init];
    if (self) {
        NSString *mailSubject = [NSString stringWithFormat:@"Inappropriate content has been added. Here are the details:\n\n%@", details];

        [self setToRecipients:[NSArray arrayWithObject:[[OTMEnvironment sharedEnvironment] inappropriateReportEmail] ]];
        [self setSubject:@"Inappropriate Content"];
        [self setMessageBody:mailSubject isHTML:NO];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
