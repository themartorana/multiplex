#import "StartupSpinnerView.h"
#import "MultiplexColorFactory.h"
#import "IndeterminateProgressIndicatorLayer.h"

@implementation StartupSpinnerView

- (void) awakeFromNib
{
    backingLayer = [CALayer layer];
    backingLayer.backgroundColor = [MultiplexColorFactory whiteThreeQuartersTransparent];
    backingLayer.cornerRadius = 10.0;
    backingLayer.frame = NSRectToCGRect([self bounds]);
    
    progressLayer = [IndeterminateProgressIndicatorLayer layer];
    progressLayer.frame = CGRectMake(([self bounds].size.width - 50.0) / 2.0, 
                                     ([self bounds].size.height - 50.0) / 2.0, 
                                     [self bounds].size.width - 100.0, 
                                     [self bounds].size.height - 100.0);
        
    [backingLayer addSublayer:progressLayer];
    
    [self setWantsLayer:YES];
    [[self layer] addSublayer:backingLayer];
}

@end
