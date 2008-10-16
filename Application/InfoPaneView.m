#import "InfoPaneView.h"
#import "ButtonLayer.h"
#import "ApplicationResources.h"
#import "CGColorFactory.h"

@implementation InfoPaneView

- (void) awakeFromNib
{
    [self setWantsLayer:YES];
    [self layer].layoutManager = [CAConstraintLayoutManager layoutManager];
    [self layer].masksToBounds = NO;
    [self layer].cornerRadius = 20.0;
    [self layer].backgroundColor = [CGColorFactory blackOneQuarterTransparent];
    
    CALayer* borderLayer = [CALayer layer];
    borderLayer.borderColor = [CGColorFactory whiteOneQuarterTransparent];
    borderLayer.borderWidth = 2.0;
    borderLayer.cornerRadius = 20.0;
    borderLayer.constraints = [NSArray arrayWithObjects:
                               [CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX],
                               [CAConstraint constraintWithAttribute:kCAConstraintMidY relativeTo:@"superlayer" attribute:kCAConstraintMidY],
                               [CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth],
                               [CAConstraint constraintWithAttribute:kCAConstraintHeight relativeTo:@"superlayer" attribute:kCAConstraintHeight],
                               nil];
    [[self layer] addSublayer:borderLayer];
    
    /*
    playButtonLayer = [PlayButtonLayer layer];
    playButtonLayer.anchorPoint = CGPointZero;
    playButtonLayer.zPosition = 1;
    playButtonLayer.constraints = [NSArray arrayWithObjects:
                                   [CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMaxX scale:1.0 offset:-40.0],
                                   [CAConstraint constraintWithAttribute:kCAConstraintMidY relativeTo:@"superlayer" attribute:kCAConstraintMinY scale:1.0 offset:40.0],
                                   [CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth scale:0.0 offset:200.0],
                                   [CAConstraint constraintWithAttribute:kCAConstraintHeight relativeTo:@"superlayer" attribute:kCAConstraintHeight scale:0.0 offset:200.0],
                                   nil];
    [[self layer] addSublayer:playButtonLayer];
    */
    
    closeButtonLayer = [ButtonLayer buttonLayerWithUpState:[ApplicationResources closeButton] downState:[ApplicationResources closeButtonDown]];
    closeButtonLayer.anchorPoint = CGPointZero;
    closeButtonLayer.zPosition = 1;
    closeButtonLayer.constraints = [NSArray arrayWithObjects:
                                    [CAConstraint constraintWithAttribute:kCAConstraintMaxX relativeTo:@"superlayer" attribute:kCAConstraintMaxX scale:1.0 offset:-10.0],
                                    [CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY scale:1.0 offset:-10.0],
                                    [CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth scale:0.0 offset:30.0],
                                    [CAConstraint constraintWithAttribute:kCAConstraintHeight relativeTo:@"superlayer" attribute:kCAConstraintHeight scale:0.0 offset:30.0],
                                    nil];
    [[self layer] addSublayer:closeButtonLayer];
   
}

- (BOOL) wantsDefaultClipping
{
    return NO;
}

- (void) dealloc
{
    [super dealloc];
}

- (void) mouseDown:(NSEvent*)theEvent
{
    CGPoint p = NSPointToCGPoint([self convertPoint:[theEvent locationInWindow] fromView:nil]);
    CALayer* layer = [closeButtonLayer hitTest:p];
    
    if (layer && layer == closeButtonLayer) {
        closeButtonLayer.isMouseDown = YES;        
    }
}

- (void) mouseUp:(NSEvent*)theEvent
{
    closeButtonLayer.isMouseDown = NO;
    
    CGPoint p = NSPointToCGPoint([self convertPoint:[theEvent locationInWindow] fromView:nil]);
    CALayer* layer = [closeButtonLayer hitTest:p];
    
    if (layer && layer == closeButtonLayer) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MultiplexCloseMovieDialog" object:nil];        
    }
}

@end
