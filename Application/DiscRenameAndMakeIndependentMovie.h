#import <Cocoa/Cocoa.h>


@interface DiscRenameAndMakeIndependentMovie : NSPanel {
    IBOutlet NSTextField* removeTextField;
    IBOutlet NSTextField* renameTextField;
}

- (IBAction) cancel:(id)sender;
- (IBAction) ok:(id)sender;

- (void) prepareForRemoveFromSet;
- (void) prepareForDiscRename;

@end
