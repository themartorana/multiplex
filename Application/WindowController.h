#import <Cocoa/Cocoa.h>

@class MainView;
@class HoverTitleView;
@class InfoPaneFormController;

@interface WindowController : NSWindowController {
    IBOutlet NSArrayController* movies;
    IBOutlet MainView* mainView;
    
    IBOutlet HoverTitleView* basicInfoView;
    IBOutlet NSView* infoPaneHostingView;
    
    IBOutlet InfoPaneFormController* infoPaneFormController;
}

@end
