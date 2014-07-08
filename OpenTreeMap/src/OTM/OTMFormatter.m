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

#import "OTMFormatter.h"

@implementation OTMFormatter : NSObject

// factor should be "display units per api (db) units"
-(id)initWithDigits:(NSUInteger)digits
              label:(NSString *)label
{

    if ((self = [super init])) {
        if (digits > 10) {
            digits = 10;
        }

        _digits = digits;
        _label = label;
    }

    return self;
}

-(NSString*)format:(CGFloat)number {
    NSString *display = [self formatWithoutUnit:number];

    if (_label != nil) {
        display = [display stringByAppendingFormat:@" %@", _label];
    }

    return display;
}

-(NSString*)formatWithoutUnit:(CGFloat)number {
    return [NSString stringWithFormat:@"%.*f", _digits, number];
}

+(NSString*)fmtOtmApiDateString:(NSString*)dateString
{
    NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];

    NSDateFormatter *isoFormatter = [[NSDateFormatter alloc] init];
    [isoFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [isoFormatter setCalendar:cal];
    [isoFormatter setLocale:[NSLocale currentLocale]];

    NSDate *date = [isoFormatter dateFromString:dateString];

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MMMM d, yyyy 'at' h:MM aaa"];
    [formatter setCalendar:cal];
    [formatter setLocale:[NSLocale currentLocale]];
    return [formatter stringFromDate:date];
}

@end
