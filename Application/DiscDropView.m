#import "DiscDropView.h"
#import "MainView.h"
#import "Movie.h"

#define DiscSimplePboardType @"DiscSimplePboardType"

@implementation DiscDropView

- (DiscDropView*) init
{
    if (self = [super init]) {
        // Register to receive drags
        [self registerForDraggedTypes:[NSArray arrayWithObject:DiscSimplePboardType]];
    }
    
    return self;
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
    /*NSPasteboard* pasteBoard = [sender draggingPasteboard];
    NSArray* fileNames = [pasteBoard propertyListForType:DiscSimplePboardType];
    NSLog(@"%@", fileNames);*/
    MainView* mv = (MainView*)[sender draggingSource];
    Movie* m = mv.hoveredMovie;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MultiplexCombineMoviesIntoSet" object:m];
    
    return YES;
}

@end
