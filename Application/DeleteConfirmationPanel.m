#import "DeleteConfirmationPanel.h"
#import "Movie.h"
#import "Disc.h"

@implementation DeleteConfirmationPanel

- (IBAction) deleteFromMultiplex:(id)sender
{
    [self orderOut:nil];
    [NSApp endSheet:self returnCode:1];
}

- (IBAction) deleteFromMultiplexAndSendToTrash:(id)sender
{
    [self orderOut:nil];
    [NSApp endSheet:self returnCode:2];
}

- (IBAction) cancel:(id)sender
{
    [self orderOut:nil];
    [NSApp endSheet:self returnCode:0];
}

- (void) prepareForDelete:(id)obj withNumberOfLocalMediaObjects:(int)num
{
    NSString* objType = nil;
    
    if ([obj isKindOfClass:[Movie class]]) {
        objType = @"Movie";
    }
    else {
        objType = @"Disc";
    }
    
    if (num == 0) {
        [deleteAndSendToTrashButton setHidden:YES];
        NSString* deleteConfirm = [NSString stringWithFormat:
                                   @"Are you sure you want to delete this %@ from the Multiplex database?",
                                   objType];
        
        [confirmationLabel setStringValue:deleteConfirm];
    }
    else {
        [deleteAndSendToTrashButton setHidden:NO];
        NSString* deleteConfirm = [NSString stringWithFormat:
                                   @"The %@ you are trying to delete has %d local media file(s) associated with it.\n\nWould you like to simply delete the %@ from the Multiplex database, or also move the associated media files to the trash?",
                                   objType, num, objType];
        
        [confirmationLabel setStringValue:deleteConfirm];        
    }
}

@end
