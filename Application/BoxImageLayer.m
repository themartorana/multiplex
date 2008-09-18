//
//  BoxImageLayer.m
//  Multiplex
//
//  Created by David Martorana on 9/18/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "BoxImageLayer.h"
#import "IndeterminateProgressIndicatorLayer.h"


@implementation BoxImageLayer

@synthesize boxImage;

- (BoxImageLayer*) init
{
    if (self = [super init]) {
        self.layoutManager = [CAConstraintLayoutManager layoutManager];
        self.levelsOfDetail = 3;
        [self setNeedsDisplay];
    }
    
    return self;
}

- (void) startSpinner
{
    // Set up our spinner
    spinnerLayer = [IndeterminateProgressIndicatorLayer layer];
    spinnerLayer.constraints = [NSArray arrayWithObjects:
                         [CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX],
                         [CAConstraint constraintWithAttribute:kCAConstraintMidY relativeTo:@"superlayer" attribute:kCAConstraintMidY scale:0.5 offset:0.0], 
                         [CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth scale:0.35 offset:0.0],
                         [CAConstraint constraintWithAttribute:kCAConstraintHeight relativeTo:@"superlayer" attribute:kCAConstraintWidth scale:0.35 offset:0.0],
                         nil
                         ];
    [self addSublayer:spinnerLayer];
    spinnerLayer.hidden = NO;
}

- (void) stopSpinner
{
    if (spinnerLayer) {
        spinnerLayer.hidden = YES;
        
        if (spinnerLayer.superlayer) {
            [spinnerLayer removeFromSuperlayer];
        }
        
        spinnerLayer = nil;
    }
}


- (void) drawInContext:(CGContextRef)c
{
    if (boxImage) {        
        
        if (spinnerLayer) {
            [self stopSpinner];
        }
        
        CIFilter* scaleFilter = [CIFilter filterWithName:@"CILanczosScaleTransform"];
        [scaleFilter setDefaults];
        [scaleFilter setValue:boxImage forKey:kCIInputImageKey];
        [scaleFilter setValue:[NSNumber numberWithFloat:self.bounds.size.height / boxImage.extent.size.height] forKey:@"inputScale"];
        CIImage* scaledImage = [scaleFilter valueForKey:kCIOutputImageKey];
        
        CIContext* context = [CIContext contextWithCGContext:c options:nil];
        [context drawImage:scaledImage inRect:self.bounds fromRect:scaledImage.extent];
    } else {
        [super drawInContext:c];
    }
}

@end
