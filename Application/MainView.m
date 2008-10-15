#import "MainView.h"
#import "Movie.h"
#import "MovieLayer.h"

#import <QuartzCore/QuartzCore.h>

@interface MainView (LayerStuff)
- (MovieLayer*) newLayerForMovie:(Movie*)movie;
- (void) layoutSublayersOfLayer:(CALayer*)layer;
@end

@interface MainView (Private)
- (void) cancelHoverTimer;
- (MovieLayer*) movieLayerForPoint:(CGPoint)p;
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context;
- (void) hoverTimerTicked:(NSTimer*)timer;
@end

@implementation MainView

@synthesize content;
@synthesize hoveredMovie;

- (void) awakeFromNib
{
    [self setWantsLayer:YES];
    CALayer* rootLayer = self.layer;
    rootLayer.layoutManager = [CAConstraintLayoutManager layoutManager];
    rootLayer.delegate = self;
    
    floorLayer = [CALayer layer];
    floorLayer.delegate = self;
    floorLayer.layoutManager = self;
    floorLayer.position = CGPointZero;
    floorLayer.constraints = [NSArray arrayWithObjects:
        [CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY],
        [CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX],
        [CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth scale:0.90 offset:0.0],
        [CAConstraint constraintWithAttribute:kCAConstraintHeight relativeTo:@"superlayer" attribute:kCAConstraintHeight scale:0.85 offset:0.0],
        nil
    ];
    [rootLayer insertSublayer:floorLayer atIndex:0];
    
    radialGradientLayer = [CALayer layer];
    radialGradientLayer.hidden = YES;
    radialGradientLayer.delegate = self;
    radialGradientLayer.position = CGPointZero;
    radialGradientLayer.frame = CGRectMake(0, 0, 100, 100);
    [radialGradientLayer setNeedsDisplay];
    [floorLayer addSublayer:radialGradientLayer];
    
    listOfLayersInOrder = [[NSMutableArray alloc] initWithObjects:[NSMutableArray array], nil];
    layersByID = [[NSMutableDictionary alloc] init];
    
    // Set up our mouse tracking area
    [self resumeTracking];
    
    hoverHighlightLayer = [[CALayer layer] retain];
    hoverHighlightLayer.borderColor = CGColorCreateGenericRGB(231.0/255.0, 111.0/255.0, 52.0/255.0, 1.0);
    hoverHighlightLayer.borderWidth = 10.0;
    hoverHighlightLayer.cornerRadius = 10.0;
    hoverHighlightLayer.hidden = YES;
    [floorLayer addSublayer:hoverHighlightLayer];
    
    hoverPlayLayer = [HoverPlayLayer layer];
    hoverPlayLayer.hidden = YES;
    [rootLayer addSublayer:hoverPlayLayer];
    [hoverPlayLayer bind:@"hoveredMovie" toObject:self withKeyPath:@"hoveredMovie" options:nil];
}


- (void) dealloc
{
    [self cancelHoverTimer];
    [layersByID release];
    [listOfLayersInOrder release];
    [hoverPlayLayer release];
    [super dealloc];
}

- (void) setContent:(id)_content
{
    if (content != _content) {
        [content release];
        content = [_content retain];
        
        if ([content isKindOfClass:[NSArrayController class]]) {
            NSArrayController* arrayController = content;
            [arrayController addObserver:self forKeyPath:@"content.@count" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
            [arrayController addObserver:self forKeyPath:@"arrangedObjects" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
        } else {
            [NSException raise:NSInvalidArgumentException format:@"content must be of type NSArrayController."];
        }
    }
}

- (void) setHoveredMovie:(Movie*)movie
{
    [CATransaction begin];
    [CATransaction setValue:[NSNumber numberWithDouble:0.0] forKey:kCATransactionAnimationDuration];
    if (movie != hoveredMovie) {
        [hoveredMovie release];
        hoveredMovie = [movie retain];

        hoverPlayLayer.hidden = YES;
        
        [self cancelHoverTimer];

        if (movie) {
            MovieLayer* movieLayer = [layersByID objectForKey:hoveredMovie.objectID];

            hoverHighlightLayer.hidden = NO;
            hoverHighlightLayer.anchorPoint = movieLayer.anchorPoint;
            hoverHighlightLayer.bounds = CGRectInset(movieLayer.bounds, -20, -20);
            hoverHighlightLayer.position = movieLayer.position;
            hoverHighlightLayer.zPosition = movieLayer.zPosition - 1;
            hoverHighlightLayer.transform = movieLayer.transform;
            
            hoverTimer = [[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(hoverTimerTicked:) userInfo:nil repeats:NO] retain];
        } else {
            hoverHighlightLayer.hidden = YES;
        }

    }
    [CATransaction commit];
}

- (void) drawLayer:(CALayer*)layer inContext:(CGContextRef)c
{
    if (layer == radialGradientLayer) {
        [NSGraphicsContext saveGraphicsState];
        [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:c flipped:YES]];
        {
            CGRect bounds = layer.bounds;
            NSPoint center = NSMakePoint(bounds.origin.x + bounds.size.width / 2.0, bounds.origin.y + bounds.size.height / 2.0);
            
            NSColor* lightGrey = [NSColor colorWithDeviceRed:154.0/255.0 green:154.0/255.0 blue:154.0/255.0 alpha:1.0];
            NSColor* darkGrey = [NSColor colorWithDeviceRed:154.0/255.0 green:154.0/255.0 blue:154.0/255.0 alpha:0.0];
            NSGradient* gradient = [[NSGradient alloc] initWithColorsAndLocations:lightGrey, (CGFloat)0.0, darkGrey, (CGFloat)1.0, nil];
            [gradient drawFromCenter:center radius:0 toCenter:center radius:MIN(bounds.size.width, bounds.size.height)/2.0 options:0];
            [gradient release];
        }
        [NSGraphicsContext restoreGraphicsState];
        
    }
}

- (void) mouseDown:(NSEvent*)theEvent
{
    /*if (!hoverPlayLayer.hidden) {
        CGPoint p = NSPointToCGPoint([self convertPoint:[theEvent locationInWindow] fromView:nil]);
        CALayer *layer = [hoverPlayLayer hitTest:p];
        if (layer && [layer isKindOfClass:[PlayButtonLayer class]]) {
            hoverPlayLayer.isMouseDown = YES;
        }
    }*/
}

- (void) mouseUp:(NSEvent*)theEvent
{
    CGPoint p = NSPointToCGPoint([self convertPoint:[theEvent locationInWindow] fromView:nil]);
    MovieLayer* movieLayer = [self movieLayerForPoint:p];
    if (movieLayer) {
        Movie* movie = [movieLayer movie];
        [(NSArrayController*)content setSelectedObjects:[NSArray arrayWithObject:movie]];
        
        if ([theEvent clickCount] == 2) {
            hoverPlayLayer.hidden = YES;
            [self cancelHoverTimer];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"MultiplexShowMovieDialog" object:nil];
        } else {
            if (![hoverPlayLayer hitTest:p]) {
                [self setHoveredMovie:movieLayer.movie];
            }
        }
    }
}

- (void) mouseMoved:(NSEvent*)theEvent
{    
    CGPoint p = NSPointToCGPoint([self convertPoint:[theEvent locationInWindow] fromView:nil]);
    MovieLayer* movieLayer = [self movieLayerForPoint:p];
    Movie* movie = movieLayer.movie;
    if ([hoverPlayLayer hitTest:p] || movie == hoveredMovie) {
        return;
    }
    hoverPlayLayer.position = CGPointMake(p.x, p.y - hoverPlayLayer.bounds.size.height + 20.0);
    [self setHoveredMovie:movie];
}

- (void) mouseExited:(NSEvent*)theEvent
{
    [self setHoveredMovie:nil];
}

- (void) pauseTracking
{
    if (mouseTrackingArea) {
        [self removeTrackingArea:mouseTrackingArea];
        [mouseTrackingArea release];
        mouseTrackingArea = nil;
    }
}

- (void) resumeTracking
{
    mouseTrackingArea = [[NSTrackingArea alloc] initWithRect:NSRectFromCGRect([self layer].bounds) 
                                                     options:(NSTrackingMouseMoved|NSTrackingActiveAlways|NSTrackingInVisibleRect|NSTrackingMouseEnteredAndExited) 
                                                       owner:self 
                                                    userInfo:nil];
    [self addTrackingArea:mouseTrackingArea];    
}

@end


#pragma mark -
@implementation MainView (Private)

- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    if ([@"content.@count" isEqualToString:keyPath]) {
        self.hoveredMovie = nil;
        NSMutableArray* allLayers = [listOfLayersInOrder objectAtIndex:0];
        int oldCount = [allLayers count];
        NSArray* allObjects = [object content];
        int count = [[object content] count];
        if (oldCount != count) {
            NSMutableArray* layersInOrder = [NSMutableArray arrayWithCapacity:count];
            NSMutableSet* keySet = [NSMutableSet setWithArray:[layersByID allKeys]];
            for (Movie* movie in allObjects) {
                NSManagedObjectID* objectID = [movie objectID];
                MovieLayer* layer = [layersByID objectForKey:objectID];
                if (!layer) {
                    layer = [self newLayerForMovie:movie];
                    [floorLayer addSublayer:layer];
                    [layersByID setObject:layer forKey:objectID];
                }
                [keySet removeObject:objectID];
                [layersInOrder addObject:layer];
            }
            for (id keyOfLayerToDelete in keySet) {
                MovieLayer* layerToDelete = [layersByID objectForKey:keyOfLayerToDelete];
                [layerToDelete removeFromSuperlayer];
                [layersByID removeObjectForKey:keyOfLayerToDelete];
            } 
            [listOfLayersInOrder replaceObjectAtIndex:0 withObject:layersInOrder];
            [floorLayer setNeedsLayout];
        }
    } else if ([@"arrangedObjects" isEqualToString:keyPath]) {
        self.hoveredMovie = nil;
        NSArray* arrangedObjects = [object arrangedObjects];

        int count = [arrangedObjects count];
        radialGradientLayer.hidden = count == 0;
        for (int i = [listOfLayersInOrder count] - 1; i > 0; i--) {
            if ([[listOfLayersInOrder objectAtIndex:i] count] > count) {
                break;
            }
            [listOfLayersInOrder removeLastObject];
        }
                
        /*  Determine which items already have layers, and which need to have
         *  layers created for them.
         */
        NSMutableArray* layersInOrder = [NSMutableArray arrayWithCapacity:count];
        for (Movie* movie in arrangedObjects) {
            NSManagedObjectID* objectID = [movie objectID];
            MovieLayer* layer = [layersByID objectForKey:objectID];
            if (!layer) {
                layer = [self newLayerForMovie:movie];
                [floorLayer addSublayer:layer];
                [layersByID setObject:layer forKey:objectID];
            }
            [layersInOrder addObject:layer];
        }
        
        /*  Keep these around for next time...
         */
        [listOfLayersInOrder addObject:layersInOrder];

        CGFloat opacity = 1.0;
        NSMutableSet* tagged = [NSMutableSet set];
        for (NSArray* layersInOrder in [listOfLayersInOrder reverseObjectEnumerator]) {
            for (CALayer* layer in layersInOrder) {
                if (![tagged containsObject:layer]) {
                    layer.opaque = (opacity == 1.0);
                    layer.opacity = opacity;
                    [tagged addObject:layer];
                }
            }
            opacity *= 0.2;
        }
        
        /*  Tell the root layer to re-layout.
         */
        [floorLayer setNeedsLayout];
    }
}

- (MovieLayer*) movieLayerForPoint:(CGPoint)p
{
    CALayer* layer = [floorLayer hitTest:p];
    while (layer) {
        if (layer == radialGradientLayer) {
            break;
        } else if ([layer isKindOfClass:[MovieLayer class]]) {
            return (MovieLayer*)layer;
        }
        layer = layer.superlayer;
    }
    return nil;
}

- (void) cancelHoverTimer 
{
    if (hoverTimer) @synchronized (hoverTimer) {
        [hoverTimer invalidate];
        [hoverTimer release];
        hoverTimer = nil;
    }
}

- (void) hoverTimerTicked:(NSTimer*)timer
{
    @synchronized (hoverTimer) {
        [hoverTimer release];
        hoverTimer = nil;
        
        [CATransaction begin];
        [CATransaction setValue:[NSNumber numberWithFloat:0.75] forKey:kCATransactionAnimationDuration];
        hoverPlayLayer.hidden = NO;
        [CATransaction commit];
    }
}

@end


CGFloat WS = 75.0;
CGFloat W = 280.0;
CGFloat H = 400.0;
CGFloat HS = 75.0;

#pragma mark -
@implementation MainView (LayerStuff)

- (MovieLayer*) newLayerForMovie:(Movie*)movie
{
    MovieLayer* layer = [MovieLayer layerWithMovie:movie];
    layer.frame = CGRectMake(0.0, 0.0, W, H);
    layer.position = CGPointZero;
    return layer;
}

- (id<CAAction>) actionForLayer:(CALayer*)layer forKey:(NSString*)key
{
    if ([key isEqualToString:@"position"]) {
        return [CAAnimation animation];
    }
    return nil;
}

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
        do {
            resultSet++;
            resultSet->rows = ++rows;
            resultSet->columns = (count / resultSet->rows) + ((count % resultSet->rows) > 0);
            resultSet->aspect = (((W+WS)/(H+HS)) * resultSet->columns / 2.0) / resultSet->rows;
            resultSet->score = resultSet->aspect - aspectToFit;
        } while (resultSet->score > -0.005);
        
        CGFloat lowScore = CGFLOAT_MAX;
        for (struct result* rp = resultSet, *rb = resultSet - rows; rp > rb; rp--) {
            if (fabsf(rp->score) < lowScore) {
                resultSet = rp;
                lowScore = fabsf(rp->score);
            }
        }
    }
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithInt:resultSet->columns], @"columns",
        [NSNumber numberWithInt:resultSet->rows], @"rows",
        nil
    ];
}

- (void) layoutSublayersOfLayer:(CALayer*)layer
{
    NSAssert(layer == floorLayer, @"wtf?");
    [CATransaction begin];
    [CATransaction setValue:[NSNumber numberWithFloat:0.5] forKey:kCATransactionAnimationDuration];
    
    /*  This base transform sets up the origin (0, 0) to the center of the 
     *  layer along the X and Y axes.
     */
    CATransform3D b = CATransform3DIdentity;
    b = CATransform3DTranslate(b, floorLayer.bounds.size.width / 2.0, floorLayer.bounds.size.height / 2.0, 0.0);

    CGSize const size = floorLayer.bounds.size;
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
    for (NSArray* layersInOrder in listOfLayersInOrder) {
        int count = [layersInOrder count];
        lastWasEmpty = !count;
        NSDictionary* parameters = [self computeParametersForSize:floorLayer.bounds.size andCount:count];
        
        columns = [[parameters objectForKey:@"columns"] floatValue];
        rows = [[parameters objectForKey:@"rows"] floatValue];
        height = (HS + ((H + WS) * rows));
        length = (WS + ((W + WS) * columns));
        radius = length / M_PI;
        if (0 == base) {
            base = height;
        }
        
        int x = 0;
        int y = rows;
        for (MovieLayer* layer in layersInOrder) {
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
                t = CATransform3DTranslate(t, chord - (length / 2.0), 0.0, -columns);
            } else {
                width = radius * 2.0;
                CGFloat theta = -chord / radius;
                t = CATransform3DTranslate(t, radius * -cos(theta), 0.0, radius * sin(theta));
                
                if (y > (columns / 2)) {
                    t = CATransform3DRotate(t, theta - M_PI/2.0, 0.0, 1.0, 0.0);
                } else {
                    t = CATransform3DRotate(t, theta + M_PI/2.0, 0.0, 1.0, 0.0);
                }
            }
            layer.transform = t;
            
            /*  Setup for the next iteration.
             */
            y -= 1;
            if (!y) {
                x++;
                y = rows;
            }
        }
    }

    if (!lastWasEmpty) {
        /*  Determine the scale that will "best" fit the screen.
         */
        CGFloat scale = size.width / width;
        if (scale * height > size.height) {
            scale = size.height / height;
        }
        
        radialGradientLayer.position = CGPointZero;
        radialGradientLayer.bounds = CGRectMake(length / 2.0, length / 2.0, width, width);
        radialGradientLayer.transform = CATransform3DRotate(b, -M_PI / 2.0, 1.0, 0.0, 0.0);
        
        /*  Add in our scale and perspective...  then throw a little rotational 
         *  "stank" on it.  ;)
         */
        CATransform3D p = CATransform3DIdentity;
        p = CATransform3DScale(p, scale, scale, 1.0);
        p = CATransform3DTranslate(p, 0.0, -height / 2.0, 0.0);
        p.m34 = 1.0 / -MAX(width, 2000);
        p = CATransform3DRotate(p, 0.1, 1.0, 0.0, 0.0);
        floorLayer.sublayerTransform = p;
    }
    
    [CATransaction commit];
}

@end
