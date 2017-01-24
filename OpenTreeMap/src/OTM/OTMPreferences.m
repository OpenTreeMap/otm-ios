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

#import "OTMPreferences.h"

NSString* const kOTMPreferencesInstance = @"kOTMPreferencesInstance";

@implementation OTMPreferences

- (id) init
{
    self = [super init];
    if (self)
    {
        [self setInstance:@""];
    }
    return self;
}

+ (OTMPreferences *)sharedPreferences
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

-(void)save
{
    [[NSUserDefaults standardUserDefaults]
     setObject:[self instance] forKey:kOTMPreferencesInstance];
}

-(void)load
{
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kOTMPreferencesInstance])
    {
        [self setInstance:[[NSUserDefaults standardUserDefaults] objectForKey:kOTMPreferencesInstance]];
    }
    else
    {
        [self setInstance:@""];
    }
}

@end
