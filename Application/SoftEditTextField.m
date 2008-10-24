#import "SoftEditTextField.h"


@implementation SoftEditTextField

- (void) awakeFromNib
{
    [self setDrawsBackground:NO];
    [self setFocusRingType:NSFocusRingTypeNone];
    [self setBordered:NO];
    [self setTextColor:[NSColor whiteColor]];
}

@end
