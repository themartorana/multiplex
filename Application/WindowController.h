#import <Cocoa/Cocoa.h>

@class MainView;

@interface WindowController : NSWindowController {
    IBOutlet NSArrayController* movies;
    IBOutlet MainView* mainView;
}

@end
