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

#import "OTMUser.h"

@implementation OTMUser

@synthesize firstName, lastName, zipcode, email, photo, userId, reputation, permissions, level, userType;

- (bool)canDeleteAnyTree
{
    // A user can always delete trees they have personally added, but only
    // privileged users can delete any tree.
    return [self hasPermission:@"delete_tree"];
}

- (bool)canApproveOrRejectPendingEdits
{
    // Normal users can only create pending rows, not update them.
    // Approving or rejecting an edit involves updating a pending
    // row so users with this permission are "approvers."
    return [self hasPermission:@"change_plotpending"] && [self hasPermission:@"change_treepending"];
}

- (bool)hasPermission:(NSString *)permission
{
    if (!permissions || !permission) {
        return false;
    }

    // Check for an exact, case-insensitive match
    for (NSString *allowed in permissions) {
        if ([[permission lowercaseString] isEqualToString:[allowed lowercaseString]]) {
            return true;
        }
    }

    // If the specified permission argument is not prefixed with "module.", check for any
    // matching permission by stripping off the module prefix.
    if ([[permission componentsSeparatedByString:@"."] count] == 1) {
        for (NSString *allowed in permissions) {
            NSArray *components = [[allowed lowercaseString] componentsSeparatedByString:@"."];
            if ([[permission lowercaseString] isEqualToString:[components objectAtIndex:1]]) {
                return true;
            }
        }
    }

    // No matches were found earler in the method.
    return false;
}

@end
