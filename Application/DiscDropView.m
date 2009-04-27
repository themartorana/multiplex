#import "DiscDropView.h"
#import "MainView.h"
#import "Movie.h"

#define DiscSimplePboardType @"DiscSimplePboardType"

@implementation DiscDropView

- (DiscDropView*) init
{
    if (self = [super init]) {
        // Register to receive drags
        [self setDelegate:self];
    }
    
    return self;
}

#pragma mark DragDropTargetView Delegate Methods

- (NSArray*) registeredDragTypesForDragDropTargetView:(DragDropTargetView*)sender
{
    return [NSArray arrayWithObject:DiscSimplePboardType];
}

- (BOOL) dragDropTargetView:(DragDropTargetView*)sender allowDragForPasteboard:(NSPasteboard*)pasteBoard
{
    return YES;
}

- (BOOL) dragDropTargetView:(DragDropTargetView*)sender acceptDragForPasteboard:(NSPasteboard*)pasteBoard fromSender:(id <NSDraggingInfo>)dragSender
{
    MainView* mv = (MainView*)[dragSender draggingSource];
    Movie* m = mv.hoveredMovie;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MultiplexCombineMoviesIntoSet" object:m];
    
    return YES;
}


@end
