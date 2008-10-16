#import "NSDate+IndyHallLabs.h"

@implementation NSDate (IndyHallLabs)

///
/// Take in yyyy-mm-dd or mm/dd/yyyy and return an NSDate
///
+ (NSDate*) dateFromShortDateString:(NSString*)dateString 
{
    if ([dateString length] != 10)
        return nil;
    
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
    // We'll figure out stupid European dd/mm/yy later
    NSMutableArray* dateparts = [[NSMutableArray alloc] initWithCapacity:3];
    
    // If the string comes in as yyyy-mm-dd
    if ([dateString rangeOfString:@"-"].location != NSNotFound)
    {
        // Split on "-"
        NSArray* datepartsTemp = [dateString componentsSeparatedByString:@"-"];
        
        // Make sure we have something
        if (datepartsTemp == nil || [datepartsTemp count] < 3)
            return nil;
        
        // Insert the year
        [dateparts insertObject:[datepartsTemp objectAtIndex:0] atIndex:0];
        
        // Insert the month
        if ([(NSString*)[datepartsTemp objectAtIndex:1] length] == 1) {
            NSString* properstring = [@"0" stringByAppendingString:(NSString*)[datepartsTemp objectAtIndex:1]];
            [dateparts insertObject:properstring atIndex:1];
        }
        else
            [dateparts insertObject:[datepartsTemp objectAtIndex:1] atIndex:1];
            
        // Insert the day
        if ([(NSString*)[datepartsTemp objectAtIndex:2] length] == 1) {
            NSString* properstring = [@"0" stringByAppendingString:(NSString*)[datepartsTemp objectAtIndex:2]];
            [dateparts insertObject:properstring atIndex:2];
        }
        else
            [dateparts insertObject:[datepartsTemp objectAtIndex:2] atIndex:2];
    }
    // If the string comes in as mm/dd/yyyy
    else if ([dateString rangeOfString:@"/"].location != NSNotFound) 
    {
        // Split on "/"
        NSArray* datepartsTemp = [dateString componentsSeparatedByString:@"/"];
        
        // Insert the year
        [dateparts insertObject:[datepartsTemp objectAtIndex:2] atIndex:0];
        
        // Insert the month
        if ([(NSString*)[datepartsTemp objectAtIndex:0] length] == 1) {
            NSString* properstring = [@"0" stringByAppendingString:(NSString*)[datepartsTemp objectAtIndex:0]];
            [dateparts insertObject:properstring atIndex:1];
        }
        else
            [dateparts insertObject:[datepartsTemp objectAtIndex:0] atIndex:1];
        
        // Insert the day
        if ([(NSString*)[datepartsTemp objectAtIndex:1] length] == 1) {
            NSString* properstring = [@"0" stringByAppendingString:(NSString*)[datepartsTemp objectAtIndex:1]];
            [dateparts insertObject:properstring atIndex:2];
        }
        else
            [dateparts insertObject:[datepartsTemp objectAtIndex:1] atIndex:2];
    }
    
    // Reconstruct the string, assuming mm/dd/yyyy
    NSMutableString* newDateString = [NSMutableString stringWithCapacity:25];
    [newDateString appendString:[dateparts objectAtIndex:0]];
    [newDateString appendString:@"-"];
    [newDateString appendString:[dateparts objectAtIndex:1]];
    [newDateString appendString:@"-"];
    [newDateString appendString:[dateparts objectAtIndex:2]];
    [newDateString appendString:@" 00:00:00 -0500"];

    // Now attempt to let NSDate do its thing
    NSDate* dateToReturn = [[NSDate alloc] initWithString:newDateString];
    return dateToReturn;
    
    [pool release];
}

@end
