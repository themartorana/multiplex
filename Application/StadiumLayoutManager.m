#import "StadiumLayoutManager.h"
#import "MultiplexColorFactory.h"
#import "Movie.h"
#import "MovieLayer.h"
#import "ApplicationResources.h"

#import <QuartzCore/QuartzCore.h>
#import <Toolkit/CALayer+IndyHallLabs.h>

@implementation StadiumLayoutManager
@synthesize listOfLayersInOrder;

- (id<MultiplexLayoutManager>) initWithManagingLayer:(CALayer*)_floorLayer
{
    if (self == [super init]) {
        _floorLayer.masksToBounds = NO;
        floorLayer = _floorLayer;
        
        radialGradientLayer = [CALayer layer];
        radialGradientLayer.hidden = YES;
        radialGradientLayer.contents = (id)[ApplicationResources textureForStadiumLayoutFloor];
        radialGradientLayer.frame = CGRectMake(0, 0, 100, 100);
        [_floorLayer addSublayer:radialGradientLayer];
        
        titleLayer = [CATextLayer layer];
        titleLayer.position = CGPointZero;
        titleLayer.wrapped = NO;
        titleLayer.alignmentMode = kCAAlignmentCenter;
        titleLayer.font = [NSFont systemFontOfSize:45.0];
        titleLayer.fontSize = 90.0;
        titleLayer.name = @"titleLayer";
        titleLayer.frame = CGRectMake(0, 0, 2000, 110);
        titleLayer.truncationMode = kCATruncationEnd;
        [_floorLayer addSublayer:titleLayer];
    }
    
    return self;
}

- (void) clearManagingLayerOfExtras
{
    [radialGradientLayer removeFromSuperlayer];
    [hoverHighlightLayer removeFromSuperlayer];
    [titleLayer removeFromSuperlayer];
}

- (void) setListOfLayersInOrder:(NSArray*)_listOfLayersInOrder
{
    if (listOfLayersInOrder) {
        [listOfLayersInOrder release];
        listOfLayersInOrder = nil;
    }
    listOfLayersInOrder = [_listOfLayersInOrder copy];
}

- (void) setListOfArrangedObjects:(NSArray*)_arrangedListOfObjects
{
    if (arrangedListOfObjects) {
        [arrangedListOfObjects release];
        arrangedListOfObjects = nil;
    }
    arrangedListOfObjects = [_arrangedListOfObjects copy];
    
    [self setHoveredMovieLayer:nil];
    
    radialGradientLayer.hidden = (!arrangedListOfObjects || [arrangedListOfObjects count] == 0);
}

- (void) setSelectedMovie:(Movie*)movie
{
    /* IGNORED */
}

- (void) setHoveredMovieLayer:(MovieLayer*)_hoveredMovieLayer;
{
    if (hoveredMovieLayer != _hoveredMovieLayer) {
//        dontLayoutBecauseOfHighlight = YES;

        [hoveredMovieLayer release];
        hoveredMovieLayer = [_hoveredMovieLayer retain];

        [CATransaction begin];
        [CATransaction setValue:[NSNumber numberWithBool:YES] forKey:kCATransactionDisableActions];
        
        Movie* movie = _hoveredMovieLayer.movie;
        if (movie){
            titleLayer.string = movie.title;
        } else {
            titleLayer.string = @" ";
        }
        
        if (_hoveredMovieLayer) {
            if (!hoverHighlightLayer) {
                hoverHighlightLayer = [CALayer layer];
                hoverHighlightLayer.borderColor = [MultiplexColorFactory multiplexOrange];
                hoverHighlightLayer.borderWidth = 10.0;
                hoverHighlightLayer.cornerRadius = 10.0;
                hoverHighlightLayer.anchorPoint = _hoveredMovieLayer.anchorPoint;
                hoverHighlightLayer.bounds = CGRectInset(_hoveredMovieLayer.bounds, -20, -20);
                hoverHighlightLayer.position = _hoveredMovieLayer.position;
                hoverHighlightLayer.zPosition = -1.0;
                [floorLayer addSublayer:hoverHighlightLayer];
            }
            hoverHighlightLayer.transform = _hoveredMovieLayer.transform;
            hoverHighlightLayer.hidden = NO;
        } else {
            hoverHighlightLayer.hidden = YES;
        }
        
        [CATransaction commit];
    }
}


static const CGFloat WS = 75.0;
static const CGFloat W = 280.0;
static const CGFloat H = 400.0;
static const CGFloat HS = 75.0;

- (NSDictionary*) computeParametersForSize:(CGSize)size andCount:(int)count
{
    CGFloat aspectToFit = size.width / size.height;
    
    struct result {
        int rows;
        int columns;    
        /**/
        CGFloat aspect;
        CGFloat score;
    }* resultSet = alloca(count * sizeof(struct result));
    bzero(resultSet, sizeof(struct result));
    
    if (count > 0) {
        int rows = 0;
        resultSet--;
        CGFloat lowScore = CGFLOAT_MAX;
        for (;;) {
            resultSet++;
            resultSet->rows = ++rows;
            resultSet->columns = (count / resultSet->rows) + ((count % resultSet->rows) > 0);
            resultSet->aspect = (((W+WS)/(H+HS)) * resultSet->columns / 2.0) / resultSet->rows;
            resultSet->score = fabsf(resultSet->aspect - aspectToFit);
            if (resultSet->score > lowScore) {
                resultSet--;
                break;
            }
            lowScore = resultSet->score;
        }
    }
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithInt:resultSet->columns], @"columns",
        [NSNumber numberWithInt:resultSet->rows], @"rows",
        nil
    ];
}

#define DEBUG_TRACE()   NSLog(@"% 4d %s", __LINE__, __PRETTY_FUNCTION__)

- (void) layoutSublayersOfLayer:(CALayer*)layer
{
    // TODO: THERE MUST A BETTER WAY!
    if (dontLayoutBecauseOfHighlight) {
        dontLayoutBecauseOfHighlight = NO;
        return;
    }
    DEBUG_TRACE();
    
    [CATransaction begin];
    [CATransaction setValue:[NSNumber numberWithDouble:([[NSApp currentEvent] modifierFlags] & NSShiftKeyMask) ? 3.0 : 0.3] forKey:kCATransactionAnimationDuration];
    
    CGFloat opacity = 1.0;
    NSMutableSet* tagged = [NSMutableSet set];
    for (NSArray* layersInOrder in [listOfLayersInOrder reverseObjectEnumerator]) {
        for (MovieLayer* layer in layersInOrder) {
            if (![tagged containsObject:layer.movie.objectID]) {
                if (NO == (layer.hidden = (opacity < 0.1))) {
                    layer.opaque = (opacity == 1.0);
                    layer.opacity = opacity;
                }
                [tagged addObject:layer.movie.objectID];
            }
        }
        opacity *= 0.2;
    }
    
    CGSize const size = layer.bounds.size;

    /*  This base transform sets up the origin (0, 0) to the center of the 
     *  layer along the X and Y axes.
     */
    CATransform3D b = CATransform3DIdentity;
    b = CATransform3DTranslate(b, size.width / 2.0, size.height / 2.0, 0.0);
    
    BOOL lastWasEmpty = YES;
    CGFloat columns = 0;
    CGFloat rows = 0;
    CGFloat height = 0;
    CGFloat width = 0;
    CGFloat radius = 0;
    CGFloat length = 0;
    
    /*  Process the rows, back-to-front.
     */
    CGFloat base = 0;
    CGFloat zBias = [listOfLayersInOrder count];
    for (NSArray* layersInOrder in listOfLayersInOrder) {
        int count = [layersInOrder count];
        lastWasEmpty = !count;
        NSDictionary* parameters = [self computeParametersForSize:layer.bounds.size andCount:count];
        
        columns = [[parameters objectForKey:@"columns"] floatValue];
        rows = [[parameters objectForKey:@"rows"] floatValue];
        height = (HS + ((H + HS) * rows));
        length = (WS + ((W + WS) * columns));
        radius = length / M_PI;
        if (0 == base) {
            base = height;
        }
        
        int x = 0;
        int y = rows;
        for (MovieLayer* sublayer in layersInOrder) {
            CGFloat chord = WS + (W / 2.0) + ((W + WS) * x);
            
            /*  Starting with the base transform, translate the layer along the
             *  Y axis.
             */
            CATransform3D t = b;
            t = CATransform3DTranslate(t, 0.0, ((H + HS) * y) - (H / 2.0), 0.0);
            
            /*  If there are fewer than five columns, we'll just grid this 
             *  thing.  Otherwise, we'll need to translate on the X and Z and 
             *  do a little rotating to make things look right.  For the 
             *  rotation, we need to go one direction on the left-hand of the 
             *  arc, and the opposite direction on the right-hand.
             */
            if (columns < 4) {
                width = length;
                t = CATransform3DTranslate(t, chord - (length / 2.0), 0.0, -(columns + zBias));
            } else {
                width = radius * 2.0;
                CGFloat theta = -chord / radius;
                t = CATransform3DTranslate(t, radius * -cos(theta), 0.0, (radius + zBias) * sin(theta));
                
                if (y > (columns / 2)) {
                    t = CATransform3DRotate(t, theta - M_PI/2.0, 0.0, 1.0, 0.0);
                } else {
                    t = CATransform3DRotate(t, theta + M_PI/2.0, 0.0, 1.0, 0.0);
                }
            }
            sublayer.transform = t;
            
            /*  Setup for the next iteration.
             */
            y -= 1;
            if (!y) {
                x++;
                y = rows;
            }
        }
        
        zBias -= 1.0;
    }
    
    if (!lastWasEmpty) {
        CGFloat const rotationalStank = 0.05;
        
        /*  Position, scale and rotate our gradient.
         */
        {
            CGFloat tWidth = radialGradientLayer.bounds.size.width;
            CGFloat scale = width / tWidth;
            CATransform3D t = b;
            t = CATransform3DTranslate(t, -tWidth / 2.0, -WS, 0.0);
            t = CATransform3DRotate(t, -M_PI / 2.0, 1.0, 0.0, 0.0);
            t = CATransform3DScale(t, scale, scale, 1.0);
            radialGradientLayer.transform = t;
        }

        /*  Position, scale and rotate our title.
         */
        {
            CGSize tSize = titleLayer.bounds.size;
            CGFloat scale = MAX(MIN(width / tSize.width, 2.0), 0.5);
            CATransform3D t = b;
            t = CATransform3DTranslate(t, -tSize.width / 2.0, -WS / 2.0, WS);
            t = CATransform3DRotate(t, -rotationalStank, 1.0, 0.0, 0.0);
            t = CATransform3DScale(t, scale, scale, 1.0);
            titleLayer.transform = t;
        }
        
        /*  Add in our scale and perspective...  then throw a little rotational 
         *  "stank" on it.  ;)
         */
        {
            CGFloat scale = size.width / width;
            if (scale * height > size.height) {
                scale = size.height / height;
            }
            CATransform3D p = CATransform3DIdentity;
            p = CATransform3DScale(p, scale, scale, 1.0);
            p = CATransform3DTranslate(p, 0.0, -height / 2.25, 0.0);
            p.m34 = 1.0 / -MAX(width, 2000);
            p = CATransform3DRotate(p, rotationalStank, 1.0, 0.0, 0.0);
            layer.sublayerTransform = p;
        }
    }
    
    [CATransaction commit];
}

@end
