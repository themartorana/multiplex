#import <Cocoa/Cocoa.h>

@class Movie;
@class InfoPaneFormController;

@interface InfoPaneBasicInfoView : NSView {
    Movie* selectedMovie;
    IBOutlet InfoPaneFormController* controller;
}

@property (retain) Movie* selectedMovie;

@end
