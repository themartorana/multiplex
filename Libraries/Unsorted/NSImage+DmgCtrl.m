#import "NSImage+DmgCtrl.h"

@implementation NSImage (DmgCtrl)

- (NSData*) PNGRepresentation
{
    [self lockFocus];
    NSBitmapImageRep* bitmapRep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect(0, 0, [self size].width, [self size].height)];
    [self unlockFocus];
    NSData* PNGData = [bitmapRep representationUsingType:NSPNGFileType properties:nil];
    [bitmapRep release];
    return PNGData;
}

@end
