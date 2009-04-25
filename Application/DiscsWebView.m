#import "DiscsWebView.h"

#define DiscSimplePboardType @"DiscSimplePboardType"

@implementation DiscsWebView

- (void) awakeFromNib
{
    [self registeredDraggedTypes:[NSArray arrayWithObject:DiscSimplePboardType]];
}

#pragma mark Dragging Stuff

- (NSDragOperation) draggingEntered:(id<NSDraggingInfo>)sender 
{
    //NSPasteboard* pasteBoard = [sender draggingPasteboard];
    return NSDragOperationCopy;
    //return NSDragOperationNone;
}

- (void) draggingExited:(id<NSDraggingInfo>)sender
{
}

- (BOOL) performDragOperation:(id<NSDraggingInfo>)sender 
{
    NSPasteboard* pasteBoard = [sender draggingPasteboard];
    NSArray* fileNames = [pasteBoard propertyListForType:DiscSimplePboardType];
    NSLog(@"%@", fileNames);
    
    return YES;
}

@end
