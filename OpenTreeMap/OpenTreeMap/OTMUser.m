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

#import "OTMUser.h"

@implementation OTMUser

@synthesize firstName, lastName, zipcode, email, photo, userId, reputation, permissions;

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
