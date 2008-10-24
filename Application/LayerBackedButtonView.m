#import "LayerBackedButtonView.h"
#import "ButtonLayer.h"
#import "ApplicationResources.h"

#import <QuartzCore/QuartzCore.h>

@implementation LayerBackedButtonView

@synthesize notificationNameToPost;

- (LayerBackedButtonView*) init
{
    if (self = [super init]) {
        backingLayer = nil;
        buttonLayer = nil;
        notificationNameToPost = nil;
    }
    
    return self;
}

- (void) dealloc{
    [backingLayer release];
    [buttonLayer release];
    [notificationNameToPost release];
    
    [super dealloc];
}

- (void) setButtonLayerButtonWithUpState:(CGImageRef)buttonUp andDownState:(CGImageRef)buttonDown
{
    //buttonLayer = [ButtonLayer buttonLayerWithUpState:[ApplicationResources playButton] downState:[ApplicationResources playButtonDown]];
    if (!backingLayer) {
        backingLayer = [[CALayer layer] retain];
        [backingLayer setFrame:[[self layer] frame]];
        [backingLayer setAnchorPoint:[[self layer] anchorPoint]];
        [self setLayer:backingLayer];
        [self setWantsLayer:YES];
    }
    
    if (buttonLayer) {
        [buttonLayer release];
        buttonLayer = nil;
    }
    
    buttonLayer = [[ButtonLayer buttonLayerWithUpState:buttonUp downState:buttonDown] retain];
    buttonLayer.anchorPoint = CGPointZero;
    buttonLayer.frame = NSRectToCGRect([self bounds]);
    [[self layer] addSublayer:buttonLayer];
    [buttonLayer setNeedsDisplay];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    if (buttonLayer) {
        buttonLayer.isMouseDown = YES;        
    }
}

- (void)mouseUp:(NSEvent *)theEvent
{
    if (buttonLayer) {
        buttonLayer.isMouseDown = NO;        
        
        if (notificationNameToPost) {
            CGPoint p = NSPointToCGPoint([self convertPoint:[theEvent locationInWindow] fromView:nil]);
            CALayer* layer = [buttonLayer hitTest:p];
            
            if (layer && layer == buttonLayer) {
                [[NSNotificationCenter defaultCenter] postNotificationName:notificationNameToPost object:nil];
            }            
        }
    }
}


@end
