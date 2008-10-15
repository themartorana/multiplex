#import <Cocoa/Cocoa.h>

@class MainView;
@class HoverTitleView;
@class InfoPaneFormController;

@interface WindowController : NSWindowController {
    IBOutlet NSArrayController* movies;
    IBOutlet MainView* mainView;
    
    IBOutlet HoverTitleView* hoverTitleView;
    IBOutlet NSView* infoPaneView;
    IBOutlet NSView* searchView;
    
    IBOutlet InfoPaneFormController* infoPaneFormController;
}

@end
