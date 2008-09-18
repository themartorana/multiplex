#import "MovieLayer.h"
#import "Movie.h"
#import "Disc.h"
#import "Media.h"
#import "IndeterminateProgressIndicatorLayer.h"

@interface MovieLayer (Private)
- (void) _startSpinner;
- (void) _stopSpinner;
@end

static void glossInterpolation(void *info, const float *input, float *output);
static float perceptualGlossFractionForColor(float *inputComponents);
static void perceptualCausticColorForColor(float *inputComponents, float *outputComponents);
static void drawGlossGradient(CGContextRef context, NSColor *color, NSRect inRect);


@implementation MovieLayer

@synthesize movie;

- (MovieLayer*) init
{
    if (self = [super init]) {
        self.layoutManager = [CAConstraintLayoutManager layoutManager];
        [self setNeedsDisplay];
        
        boxImageLayer = [CATiledLayer layer];
        boxImageLayer.delegate = self;
        boxImageLayer.levelsOfDetail = 5;
        boxImageLayer.levelsOfDetailBias = 1;
        boxImageLayer.constraints = [NSArray arrayWithObjects:
            [CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX],
            [CAConstraint constraintWithAttribute:kCAConstraintMidY relativeTo:@"superlayer" attribute:kCAConstraintMidY],
            [CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth],
            [CAConstraint constraintWithAttribute:kCAConstraintHeight relativeTo:@"superlayer" attribute:kCAConstraintHeight],
            nil
        ];
        [self addSublayer:boxImageLayer];
    }
    return self;
}

- (void) dealloc
{
    if (boxImage) {
        CFRelease(boxImage);
    }
    [super dealloc];
}

- (void) setMovie:(Movie*)_movie 
{
    movie = _movie;
    
    BOOL fullBreak = false;
    
    // Look for the first instance of a cover
    NSArray* discs = [movie.allDiscs allObjects];

    for (Disc* disc in discs) {
        NSArray* discMedia = [disc.allMedia allObjects];

        for (Media* media in discMedia) {
            if (media.url && [media.url length] > 0) {
                NSString* url = [[media.url stringByAppendingPathComponent:@"QuickLook"] stringByAppendingPathComponent:@"FrontCover.png"];
                url = [url stringByReplacingOccurrencesOfString:@"file:/localhost/" withString:@"file:///"];
                
                // Call out to it.
                NSURL* imageURL = [NSURL URLWithString:url];
                NSURLRequest* request = [NSURLRequest requestWithURL:imageURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5.0];
                
                if ([NSURLConnection canHandleRequest:request]) {
                    [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
                    
                    [self _startSpinner];
                    
                    fullBreak = YES;
                    break;
                }
            }
        }
        
        if (fullBreak) {
            break;
        }        
    }
}

- (void) drawInContext:(CGContextRef)c
{
    drawGlossGradient(c, [NSColor colorWithDeviceRed:0.05f green:0.05f blue:0.05f alpha:1.0], NSRectFromCGRect(self.bounds));
}

- (void) drawLayer:(CALayer*)layer inContext:(CGContextRef)c
{
    if (layer == boxImageLayer) {
        if (boxImage) {
            CGContextDrawImage(c, layer.bounds, boxImage);
            [self _stopSpinner];
        }
    }
}


#pragma mark Private Methods

- (void) _startSpinner
{
    NSAssert(!spinnerLayer, @"why isn't this nil?");
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


- (void) _stopSpinner
{
    if (spinnerLayer) {
        spinnerLayer.hidden = YES;
        [spinnerLayer removeFromSuperlayer];
        spinnerLayer = nil;
    }
}


#pragma mark NSURLConnection Delegate Methods

- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSAssert(!imageData, @"why isn't this nil?");
    imageData = [[NSMutableData alloc] init];
}

- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError*)error
{
    [self _stopSpinner];
    [imageData release];
    imageData = nil;
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [imageData appendData:data];
}


- (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, nil);
    if (imageSource) {
        boxImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil);
        [boxImageLayer setNeedsDisplay];
        CFRelease(imageSource);
    } 
     
    [imageData release];
    imageData = nil;
    [connection release];
    connection = nil;
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

