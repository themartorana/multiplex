#import "IndeterminateProgressIndicatorLayer.h"

@interface IndeterminateProgressIndicatorLayer (Private)

- (void) _setupAnimation;

@end


@implementation IndeterminateProgressIndicatorLayer
static CGPDFDocumentRef radial = nil;

+ (void) initialize
{
	radial = CGPDFDocumentCreateWithURL((CFURLRef)[NSURL fileURLWithPath:[[NSBundle bundleForClass:self] pathForResource:@"Progress" ofType:@"pdf"]]);
}

- (id) init
{
    if (self = [super init]) {
        [self setNeedsDisplayOnBoundsChange:YES];
	}
	return self;
}

- (void) drawInContext:(CGContextRef)c
{
    if (!isAnimationSetup) {
        [self _setupAnimation];        
    }
    
	CGContextDrawPDFDocument(c, self.bounds, radial, 1);
}

- (void) _setupAnimation
{
    NSMutableArray* steps = [NSMutableArray array];
    float time = 0.0;
    for (int i = 0; i < 12; i++) {
        CABasicAnimation* a = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        [a setBeginTime:time];
        [a setDuration:0.0];
        [a setFillMode:kCAFillModeForwards];
        [a setFromValue:[NSNumber numberWithDouble:-i*(2*M_PI)/12]];
        [a setToValue:[NSNumber numberWithDouble:-(i+1)*(2*M_PI)/12]];
        [a setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
        [steps addObject:a];
        time += 0.1;
    }
    CAAnimationGroup* g = [CAAnimationGroup animation];
    [g setAnimations:steps];
    [g setDuration:time];
    [g setRepeatCount:DBL_MAX];
    [self addAnimation:g forKey:@"hidden"];
    //[self addAnimation:g forKey:nil];
    
    [self setNeedsDisplay];
    isAnimationSetup = YES;
}

@end
