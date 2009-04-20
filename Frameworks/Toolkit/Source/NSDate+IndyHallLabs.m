#import "NSDate+IndyHallLabs.h"

@implementation NSDate (IndyHallLabs)

///
/// Take in yyyy-mm-dd or mm/dd/yyyy and return an NSDate
///
+ (NSDate*) dateFromShortDateString:(NSString*)dateString 
{
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    NSDate* dateToReturn = [dateFormatter dateFromString:dateString];
    [dateFormatter release];
    return dateToReturn;
}

@end
