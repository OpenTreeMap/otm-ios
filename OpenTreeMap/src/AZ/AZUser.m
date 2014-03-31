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

#import "AZUser.h"

@implementation AZUser

@synthesize keychain, loggedIn;

-(NSString *)username {
    return [keychain objectForKey:(__bridge id)kSecAttrAccount];
}

-(NSString *)password {
    return [keychain objectForKey:(__bridge id)kSecValueData];
}

-(void)setUsername:(NSString *)user {
    [keychain setObject:user forKey:(__bridge id)kSecAttrAccount];
}

-(void)setPassword:(NSString *)pass {
    [keychain setObject:pass forKey:(__bridge id)kSecValueData];
}

-(void)logout {
    [self setUsername:nil];
    // Keychain does not allow v_Data (the password) to be nil,
    // so we set it to the empty string, which is an invalid password
    [self setPassword:@""];
}

@end
