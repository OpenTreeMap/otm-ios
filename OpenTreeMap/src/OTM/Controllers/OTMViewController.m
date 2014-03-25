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

#import "OTMViewController.h"

@interface OTMViewController ()

@end

@implementation OTMViewController

- (NSString *)buildAddressStringFromPlotDictionary:(NSDictionary *)dict {
    NSMutableDictionary *plotDict = [dict objectForKey:@"plot"];
    NSArray *keys = @[@"address_street", @"address_city", @"address_zip"];

    NSMutableArray *addressComponents = [[NSMutableArray alloc] initWithCapacity:[keys count]];

    for (NSString *key in keys) {
        NSString *component = [plotDict objectForKey:key];
        if (component != nil && ![component isEqualToString: @""] && ![component  isEqualToString: @"<null>"]) {
            [addressComponents addObject:component];
        }
    }

    if ([addressComponents count] > 0) {
        return [addressComponents componentsJoinedByString:@" "];
    } else {
        return @"No Address";
    }
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
