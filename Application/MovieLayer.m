#import "MovieLayer.h"
#import "Movie.h"
#import "BoxArt.h"
#import "Disc.h"
#import "Media.h"
#import "IndeterminateProgressIndicatorLayer.h"
#import "Activity.h"
#import "MultiplexColorFactory.h"

static void glossInterpolation(void *info, const float *input, float *output);
static float perceptualGlossFractionForColor(float *inputComponents);
static void perceptualCausticColorForColor(float *inputComponents, float *outputComponents);
static void drawGlossGradient(CGContextRef context, NSColor *color, NSRect inRect);
static void drawTitleLayer(CGContextRef context, NSRect inRect, NSString* title); 

@implementation MovieLayer

@synthesize movie;
@synthesize boxArtImage;

@dynamic upLayer;
@dynamic downLayer;
@dynamic leftLayer;
@dynamic rightLayer;

+ (id) layerWithMovie:(Movie*)movie
{
    return [[[MovieLayer alloc] initWithMovie:movie] autorelease];
}

- (MovieLayer*) initWithMovie:(Movie*)_movie
{    
    NSAssert(_movie, @"wtf?");
    if (self = [super init]) {
        movie = [_movie retain];
        self.layoutManager = [CAConstraintLayoutManager layoutManager];
        self.borderColor = [MultiplexColorFactory moveLayerBorderColor];

        /*  Gradient
         */
        gradientLayer = [CALayer layer];
        gradientLayer.delegate = self;
        gradientLayer.constraints = [NSArray arrayWithObjects:
            [CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX],
            [CAConstraint constraintWithAttribute:kCAConstraintMidY relativeTo:@"superlayer" attribute:kCAConstraintMidY],
            [CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth],
            [CAConstraint constraintWithAttribute:kCAConstraintHeight relativeTo:@"superlayer" attribute:kCAConstraintHeight],
            nil
        ];
        [self addSublayer:gradientLayer];
        [gradientLayer setNeedsDisplay];
        
        /*  Box Image 
         */
        boxImageLayer = [CATiledLayer layer];
        boxImageLayer.levelsOfDetail = 5;
        boxImageLayer.levelsOfDetailBias = 1;
        boxImageLayer.delegate = self;
        boxImageLayer.constraints = [NSArray arrayWithObjects:
            [CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX],
            [CAConstraint constraintWithAttribute:kCAConstraintMidY relativeTo:@"superlayer" attribute:kCAConstraintMidY],
            [CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth],
            [CAConstraint constraintWithAttribute:kCAConstraintHeight relativeTo:@"superlayer" attribute:kCAConstraintHeight],
            nil
        ];
        [self addSublayer:boxImageLayer];

        [movie addObserver:self forKeyPath:@"availableDiscCount" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:nil];
        [movie addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:nil];
        [movie addObserver:self forKeyPath:@"boxArt.imageData" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:nil];
    }
    return self;
}

- (void) dealloc
{
    [movie removeObserver:self forKeyPath:@"availableDiscCount"];
    [movie removeObserver:self forKeyPath:@"title"];
    [movie removeObserver:self forKeyPath:@"boxArt.imageData"];
    [movie release];
    [boxArtImage release];
    [super dealloc];
}

- (void) setBoxArtImage:(id)_boxArtImage
{
    if (boxArtImage != _boxArtImage) {
        [boxArtImage release];
        boxArtImage = [_boxArtImage retain];
        [boxImageLayer setNeedsDisplay];
    }
}

- (void) drawLayer:(CALayer*)layer inContext:(CGContextRef)c
{
    if (layer == boxImageLayer) {
        CGContextDrawImage(c, layer.bounds, (CGImageRef)boxArtImage);
    } else if (layer == gradientLayer) {
        drawGlossGradient(c, [NSColor colorWithDeviceRed:0.05f green:0.05f blue:0.05f alpha:1.0], NSRectFromCGRect(self.bounds));
        drawTitleLayer(c, NSRectFromCGRect(self.bounds), movieTitle);
    }
}

- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    if ([keyPath isEqualToString:@"availableDiscCount"]) {
        int availableDiscCount = [[movie availableDiscCount] intValue];
        if (smokeLayer && availableDiscCount) {
            [smokeLayer removeFromSuperlayer];
            smokeLayer = nil;
        } else if (!smokeLayer && !availableDiscCount) {
            smokeLayer = [CALayer layer];
            smokeLayer.zPosition = 1;
            smokeLayer.backgroundColor = [MultiplexColorFactory blackOneQuarterTransparent];
            //smokeLayer.borderColor = [MultiplexColorFactory multiplexOrange];
            //smokeLayer.borderWidth = 10;
            smokeLayer.constraints = [NSArray arrayWithObjects:
                [CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX],
                [CAConstraint constraintWithAttribute:kCAConstraintMidY relativeTo:@"superlayer" attribute:kCAConstraintMidY],
                [CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth scale:1.0 offset:20],
                [CAConstraint constraintWithAttribute:kCAConstraintHeight relativeTo:@"superlayer" attribute:kCAConstraintHeight scale:1.0 offset:20],
                nil
            ];
            [self addSublayer:smokeLayer];
        }
    } else if ([keyPath isEqualToString:@"title"]) {
        if ([keyPath isEqualToString:@"title"]) {
            if (movieTitle) {
                [movieTitle release];
                movieTitle = nil;
            }
            movieTitle = [(NSString*)[object valueForKeyPath:keyPath] retain];
            
            // TODO: Redraw the text layer if necessary
            [gradientLayer setNeedsDisplay];
        }
    } else if ([keyPath isEqualToString:@"boxArt.imageData"]) {
        CGImageRef newBoxArtImage = [(Movie*)object boxArt].image;
        [self setBoxArtImage:(id)newBoxArtImage];
    }
}

- (void) clearMoveData
{
    self.upLayer = nil;
    self.downLayer = nil;
    self.leftLayer = nil;
    self.rightLayer = nil;
}

@end


#pragma mark Gradient Stuffs

typedef struct {
    float color[4];
    float caustic[4];
    float expCoefficient;
    float expScale;
    float expOffset;
    float initialWhite;
    float finalWhite;
} GlossParameters;

void glossInterpolation(void *info, const float *input, float *output)
{
    GlossParameters *params = (GlossParameters *)info;
    
    float progress = *input;
    if (progress < 0.5)
    {
        progress = progress * 2.0;
        
        progress =
        1.0 - params->expScale * (expf(progress * -params->expCoefficient) - params->expOffset);
        
        float currentWhite = progress * (params->finalWhite - params->initialWhite) + params->initialWhite;
        
        output[0] = params->color[0] * (1.0 - currentWhite) + currentWhite;
        output[1] = params->color[1] * (1.0 - currentWhite) + currentWhite;
        output[2] = params->color[2] * (1.0 - currentWhite) + currentWhite;
        output[3] = params->color[3] * (1.0 - currentWhite) + currentWhite;
    }
    else
    {
        progress = (progress - 0.5) * 2.0;
        
        progress = params->expScale *
        (expf((1.0 - progress) * -params->expCoefficient) - params->expOffset);
        
        output[0] = params->color[0] * (1.0 - progress) + params->caustic[0] * progress;
        output[1] = params->color[1] * (1.0 - progress) + params->caustic[1] * progress;
        output[2] = params->color[2] * (1.0 - progress) + params->caustic[2] * progress;
        output[3] = params->color[3] * (1.0 - progress) + params->caustic[3] * progress;
    }
}

float perceptualGlossFractionForColor(float *inputComponents)
{
    const float REFLECTION_SCALE_NUMBER = 0.2;
    const float NTSC_RED_FRACTION = 0.299;
    const float NTSC_GREEN_FRACTION = 0.587;
    const float NTSC_BLUE_FRACTION = 0.114;
    
    float glossScale =
    NTSC_RED_FRACTION * inputComponents[0] +
    NTSC_GREEN_FRACTION * inputComponents[1] +
    NTSC_BLUE_FRACTION * inputComponents[2];
    glossScale = pow(glossScale, REFLECTION_SCALE_NUMBER);
    return glossScale;
}

void perceptualCausticColorForColor(float *inputComponents, float *outputComponents)
{
    const float CAUSTIC_FRACTION = 0.20;
    const float COSINE_ANGLE_SCALE = 0.4;
    const float MIN_RED_THRESHOLD = 0.95;
    const float MAX_BLUE_THRESHOLD = 0.7;
    const float GRAYSCALE_CAUSTIC_SATURATION = 0.2;
    
    NSColor *source =
    [NSColor
     colorWithCalibratedRed:inputComponents[0]
     green:inputComponents[1]
     blue:inputComponents[2]
     alpha:inputComponents[3]];
    
    float hue, saturation, brightness, alpha;
    [source getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
    
    float targetHue, targetSaturation, targetBrightness;
    [[NSColor yellowColor] getHue:&targetHue saturation:&targetSaturation brightness:&targetBrightness alpha:&alpha];
    
    if (saturation < 1e-3)
    {
        hue = targetHue;
        saturation = GRAYSCALE_CAUSTIC_SATURATION;
    }
    
    if (hue > MIN_RED_THRESHOLD)
    {
        hue -= 1.0;
    }
    else if (hue > MAX_BLUE_THRESHOLD)
    {
        [[NSColor magentaColor] getHue:&targetHue saturation:&targetSaturation brightness:&targetBrightness alpha:&alpha];
    }
    
    float scaledCaustic = CAUSTIC_FRACTION * 0.5 * (1.0 + cos(COSINE_ANGLE_SCALE * M_PI * (hue - targetHue)));
    
    NSColor *targetColor =
    [NSColor
     colorWithCalibratedHue:hue * (1.0 - scaledCaustic) + targetHue * scaledCaustic
     saturation:saturation
     brightness:brightness * (1.0 - scaledCaustic) + targetBrightness * scaledCaustic
     alpha:inputComponents[3]];
    [targetColor getComponents:outputComponents];
}

void drawTitleLayer(CGContextRef context, NSRect inRect, NSString* title)
{
    NSGraphicsContext *nsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:context flipped:NO];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:nsContext];
    
    NSMutableParagraphStyle* pStyle = [[NSMutableParagraphStyle alloc] init];
    [pStyle setParagraphStyle:[NSParagraphStyle defaultParagraphStyle]];
    [pStyle setAlignment:NSCenterTextAlignment];
    
    NSDictionary* atts = [NSDictionary dictionaryWithObjectsAndKeys:
                          pStyle, NSParagraphStyleAttributeName,
                          [NSColor colorWithCalibratedWhite:1.0 alpha:1.0], NSForegroundColorAttributeName,
                          [NSFont boldSystemFontOfSize:40.0], NSFontAttributeName,
                          nil];
    
    
    float width = (CGFloat)inRect.size.width * 0.9;
    float height = (CGFloat)inRect.size.height * 0.9;
    NSRect titleRect = NSMakeRect(((CGFloat)inRect.size.width - width) / 2.0, 
                                  ((CGFloat)inRect.size.height - height) / 2.0,
                                  width, 
                                  height);
    
    [title drawInRect:titleRect withAttributes:atts];
    [pStyle release];
    
    [NSGraphicsContext restoreGraphicsState];
}

void drawGlossGradient(CGContextRef context, NSColor *color, NSRect inRect)
{
    const float EXP_COEFFICIENT = 1.2;
    const float REFLECTION_MAX = 0.40;
    const float REFLECTION_MIN = 0.10;
    
    GlossParameters params;
    
    params.expCoefficient = EXP_COEFFICIENT;
    params.expOffset = expf(-params.expCoefficient);
    params.expScale = 1.0 / (1.0 - params.expOffset);
    
    NSColor *source =
    [color colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    [source getComponents:params.color];
    if ([source numberOfComponents] == 3)
    {
        params.color[3] = 1.0;
    }
    
    perceptualCausticColorForColor(params.color, params.caustic);
    
    float glossScale = perceptualGlossFractionForColor(params.color);
    
    params.initialWhite = glossScale * REFLECTION_MAX;
    params.finalWhite = glossScale * REFLECTION_MIN;
    
    static const float input_value_range[2] = {0, 1};
    static const float output_value_ranges[8] = {0, 1, 0, 1, 0, 1, 0, 1};
    CGFunctionCallbacks callbacks = {0, glossInterpolation, NULL};
    
    CGFunctionRef gradientFunction = CGFunctionCreate(
                                                      (void *)&params,
                                                      1, // number of input values to the callback
                                                      input_value_range,
                                                      4, // number of components (r, g, b, a)
                                                      output_value_ranges,
                                                      &callbacks);
    
    CGPoint startPoint = CGPointMake(NSMinX(inRect), NSMaxY(inRect));
    CGPoint endPoint = CGPointMake(NSMinX(inRect), NSMinY(inRect));
    
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGShadingRef shading = CGShadingCreateAxial(colorspace, startPoint,
                                                endPoint, gradientFunction, FALSE, FALSE);
    
    CGContextSaveGState(context);
    CGContextClipToRect(context, NSRectToCGRect(inRect));
    CGContextDrawShading(context, shading);
    CGContextRestoreGState(context);

    CGShadingRelease(shading);
    CGColorSpaceRelease(colorspace);
    CGFunctionRelease(gradientFunction);
}

