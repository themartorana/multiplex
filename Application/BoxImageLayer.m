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
    idpil = [IndeterminateProgressIndicatorLayer layer];
    idpil.constraints = [NSArray arrayWithObjects:
                         [CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX],
                         [CAConstraint constraintWithAttribute:kCAConstraintMidY relativeTo:@"superlayer" attribute:kCAConstraintMidY scale:0.5 offset:0.0], 
                         [CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth scale:0.35 offset:0.0],
                         [CAConstraint constraintWithAttribute:kCAConstraintHeight relativeTo:@"superlayer" attribute:kCAConstraintWidth scale:0.35 offset:0.0],
                         nil
                         ];
    [self addSublayer:idpil];
    idpil.hidden = NO;
}

- (void) stopSpinner
{
    if (idpil) {
        idpil.hidden = YES;
        
        if (idpil.superlayer) {
            [idpil removeFromSuperlayer];
        }
        
        idpil = nil;
    }
}


- (void) drawInContext:(CGContextRef)c
{
    CIImage* image = [self valueForKey:@"$image"];
    if (image) {        
        
        if (idpil) {
            [self stopSpinner];
        }
        
        CIFilter* scaleFilter = [CIFilter filterWithName:@"CILanczosScaleTransform"];
        [scaleFilter setDefaults];
        [scaleFilter setValue:image forKey:kCIInputImageKey];
        [scaleFilter setValue:[NSNumber numberWithFloat:self.bounds.size.height / image.extent.size.height] forKey:@"inputScale"];
        CIImage* scaledImage = [scaleFilter valueForKey:kCIOutputImageKey];
        
        CIContext* context = [CIContext contextWithCGContext:c options:nil];
        [context drawImage:scaledImage inRect:self.bounds fromRect:scaledImage.extent];
    } else {
        [super drawInContext:c];
    }
}

@end
