#import <Cocoa/Cocoa.h>

@class MainView;
@class BasicInfoView;
@class InfoPaneFormController;
@class InfoPaneHostingView;

@interface WindowController : NSWindowController {
    IBOutlet NSArrayController* movies;
    IBOutlet MainView* mainView;
    
    IBOutlet BasicInfoView* basicInfoView;
    IBOutlet InfoPaneHostingView* infoPaneHostingView;
    
    IBOutlet InfoPaneFormController* infoPaneFormController;
}

@end
