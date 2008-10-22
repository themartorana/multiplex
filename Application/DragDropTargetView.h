#import <Cocoa/Cocoa.h>

@interface DragDropTargetView : NSView {
	int _phase;
	NSTimer* _timer;
	BOOL _highlighted;
    IBOutlet id delegate;
}

@property (retain) id delegate;

@end

@interface NSObject (DragDropTargetView)
- (BOOL) dragDropTargetView:(DragDropTargetView*)sender allowDragForPasteboard:(NSPasteboard*)pasteBoard;
- (BOOL) dragDropTargetView:(DragDropTargetView*)sender acceptDragForPasteboard:(NSPasteboard*)pasteBoard;
@end

