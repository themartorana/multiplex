#import <QuartzCore/QuartzCore.h>
#import "IndeterminateProgressIndicatorLayer.h"
#import "BoxImageLayer.h"

@class Movie;

@interface MovieLayer : CALayer {
    Movie* movie;
    NSMutableData* imageData;
    IndeterminateProgressIndicatorLayer* idpil;
    BoxImageLayer* boxImageLayer; 
}

@property (retain) Movie* movie;

static void glossInterpolation(void *info, const float *input, float *output);
float perceptualGlossFractionForColor(float *inputComponents);
void perceptualCausticColorForColor(float *inputComponents, float *outputComponents);
void DrawGlossGradient(CGContextRef context, NSColor *color, NSRect inRect);

@end
