#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@class PlayButtonLayer;
@class Disc;

@interface DiscPlayLayer : CALayer {

    PlayButtonLayer* playButtonLayer;
    CATextLayer* discNumberTitle;
    CATextLayer* descriptionLayer;
    
    Disc* disc;
    
    BOOL hovered;
}

@property (retain) Disc* disc;
@property BOOL hovered;

- (void) setUpPlayLayer;

@end
