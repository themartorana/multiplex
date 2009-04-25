#import "DiscRenameAndMakeIndependentMovie.h"


@implementation DiscRenameAndMakeIndependentMovie

- (IBAction) cancel:(id)sender;
{
    [self orderOut:nil];
    [NSApp endSheet:self returnCode:NSRunAbortedResponse];
}

- (IBAction) ok:(id)sender
{
    [self orderOut:nil];
    [NSApp endSheet:self returnCode:NSRunStoppedResponse];
}

- (void) prepareForRemoveFromSet
{
    [removeTextField setHidden:NO];
    [renameTextField setHidden:YES];
}

- (void) prepareForDiscRename
{
    [removeTextField setHidden:YES];
    [renameTextField setHidden:NO];
}

@end
