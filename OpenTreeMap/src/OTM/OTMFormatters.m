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

#import "OTMFormatters.h"

@implementation OTMFormatters

+(NSString*)fmtIn:(NSNumber*)number 
{
    return [NSString stringWithFormat:@"%0.2f in",[number floatValue]];
}

+(NSString*)fmtFt:(NSNumber*)number 
{
    return [NSString stringWithFormat:@"%0.2f ft",[number floatValue]];
}

+(NSString*)fmtM:(NSNumber*)number 
{
    return [NSString stringWithFormat:@"%0.2f m",[number floatValue]];
}

+(NSString*)fmtUnitDict:(NSDictionary*)d 
{
    id unit = [d objectForKey:@"unit"];
    if (nil == unit) {
        unit = @"";
    }

    return [NSString stringWithFormat:@"%0.1f %@", [[d valueForKey:@"value"] floatValue], unit];
}

+(NSString*)fmtDollarsDict:(NSDictionary*)d
{
    return [NSString stringWithFormat:@"$%0.2f", [[d valueForKey:@"dollars"] floatValue]];
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

+(NSString*)fmtObject:(id)obj withKey:(NSString*)key {
    if (obj == nil || [[obj description] isEqualToString:@"<null>"]) {
        return @"";
    } else if (key == nil || [key length] == 0) {
        return [obj description];
    } else {
        return [OTMFormatters performSelector:NSSelectorFromString(key) withObject:obj];
    }
}

@end
