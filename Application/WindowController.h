#import <Cocoa/Cocoa.h>

@class MainView;
@class InfoView;

@interface WindowController : NSWindowController {
    IBOutlet NSArrayController* movies;
    IBOutlet MainView* mainView;
    IBOutlet InfoView* infoView;
}

@end
