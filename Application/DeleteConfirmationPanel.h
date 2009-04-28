#import <Cocoa/Cocoa.h>


@interface DeleteConfirmationPanel : NSPanel {
    IBOutlet NSTextField* confirmationLabel;
    IBOutlet NSButton* deleteAndSendToTrashButton;
}

- (IBAction) deleteFromMultiplex:(id)sender;
- (IBAction) deleteFromMultiplexAndSendToTrash:(id)sender;
- (IBAction) cancel:(id)sender;

- (void) prepareForDelete:(id)obj withNumberOfLocalMediaObjects:(int)num;

@end
