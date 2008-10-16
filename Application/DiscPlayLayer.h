#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@class ButtonLayer;
@class Disc;

@interface DiscPlayLayer : CALayer {

    ButtonLayer* playButtonLayer;
    ButtonLayer* greyPlayButtonLayer;
    CATextLayer* discNumberTitle;
    CATextLayer* descriptionLayer;
    
    Disc* disc;
    
    BOOL hovered;
}

@property (retain) Disc* disc;
@property BOOL hovered;

- (void) setUpPlayLayer;

@end
