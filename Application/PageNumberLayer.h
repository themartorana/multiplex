#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@interface PageNumberLayer : CALayer {
    int pageNumber;
    CATextLayer* pageNumberTextLayer;
}

@property int pageNumber;

@end
