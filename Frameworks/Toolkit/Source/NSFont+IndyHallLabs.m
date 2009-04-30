#import "NSFont+IndyHallLabs.h"

@implementation NSFont (IndyHallLabs)

- (BOOL)supportsBold 
{ 
    NSFontManager* fontManager = [NSFontManager sharedFontManager]; 
    if (self != [fontManager convertFont:self toHaveTrait:NSBoldFontMask] ||  
        self != [fontManager convertFont:self toNotHaveTrait:NSBoldFontMask]) { 
        return YES; 
    } 
    return NO; 
} 

- (BOOL)supportsItalics 
{ 
    NSFontManager* fontManager = [NSFontManager sharedFontManager]; 
    if (self != [fontManager convertFont:self toHaveTrait:NSItalicFontMask] ||  
        self != [fontManager convertFont:self toNotHaveTrait:NSItalicFontMask]) { 
        return YES; 
    } 
    return NO; 
} 

@end
