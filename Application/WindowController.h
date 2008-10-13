#import <Cocoa/Cocoa.h>

@class MainView;
@class BasicInfoView;
@class InfoPaneFormController;

@interface WindowController : NSWindowController {
    IBOutlet NSArrayController* movies;
    IBOutlet MainView* mainView;
    
    IBOutlet BasicInfoView* basicInfoView;
    IBOutlet NSView* infoPaneHostingView;
    
    IBOutlet InfoPaneFormController* infoPaneFormController;
}

@end
