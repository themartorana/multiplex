#import "TextView.h"
#import "MultiplexColorFactory.h"

#import <QuartzCore/QuartzCore.h>

@implementation TextView

@synthesize text;

- (void) dealloc
{
    [textLayer release];
    [super dealloc];
}

- (void) awakeFromNib
{
    text = @"";
    
    // Set up the text layer
    CALayer* selfLayer = [self layer];

    CALayer* layer = [CALayer layer];
    layer.anchorPoint = selfLayer.anchorPoint;
    layer.frame = selfLayer.frame;
    layer.layoutManager = [CAConstraintLayoutManager layoutManager];
    
    [self setLayer:layer];
    [self setWantsLayer:YES];
    
    textLayer = [[CATextLayer layer] retain];
    textLayer.foregroundColor = [MultiplexColorFactory white];
    textLayer.alignmentMode = kCAAlignmentCenter;
    textLayer.truncationMode = kCATruncationEnd;
    textLayer.constraints = [NSArray arrayWithObjects:
                             [CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMinX],
                             [CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"superlayer" attribute:kCAConstraintMinY],
                             [CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth],
                             [CAConstraint constraintWithAttribute:kCAConstraintHeight relativeTo:@"superlayer" attribute:kCAConstraintHeight],
                             nil];
    [self setHasShadow:YES];
    [layer addSublayer:textLayer];
    
    [textLayer bind:@"string" toObject:self withKeyPath:@"text" options:nil];
    self.text = @"Title Goes Here";
}

- (void) setHasShadow:(BOOL)hasShadow
{
    if (hasShadow) {
        textLayer.shadowColor = [MultiplexColorFactory black];
        textLayer.shadowOpacity = 0.8;
    }
    else {
        textLayer.shadowColor = [MultiplexColorFactory clear];
    }
}

- (void) setBackgroundColor:(CGColorRef)_color
{
    textLayer.backgroundColor = _color;
}

- (void) setForegroundColor:(CGColorRef)_color
{
    textLayer.foregroundColor = _color;
}

@end
