#import "MainView.h"
#import "Movie.h"
#import "MovieLayer.h"
#import "ButtonLayer.h"
#import "MultiplexColorFactory.h"
#import "StadiumLayoutManager.h"

#import <Toolkit/Toolkit.h>
#import <QuartzCore/QuartzCore.h>

@interface MainView (LayerStuff)
- (MovieLayer*) newLayerForMovie:(Movie*)movie;
@end

@interface MainView (Private)
- (void) cancelHoverTimer;
- (MovieLayer*) movieLayerForPoint:(CGPoint)p;
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context;
- (void) hoverTimerTicked:(NSTimer*)timer;
- (void) _restartMouseTracking;
@end

@implementation MainView

@synthesize content;
@synthesize hoveredMovie;
@synthesize floorLayerLayoutManagerClass;

- (void) awakeFromNib
{    
    CALayer* rootLayer = [self layer];
    rootLayer.anchorPoint = CGPointZero;
    rootLayer.frame = [[self layer] frame];
    rootLayer.layoutManager = [CAConstraintLayoutManager layoutManager];
    rootLayer.delegate = self;
    [self setLayer:rootLayer];
    [self setWantsLayer:YES];
    
    floorLayer = [CALayer layer];
    floorLayer.delegate = self;
    floorLayer.position = CGPointZero;
    floorLayer.constraints = [NSArray arrayWithObjects:
        [CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY],
        [CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX],
        [CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth scale:0.90 offset:0.0],
        [CAConstraint constraintWithAttribute:kCAConstraintHeight relativeTo:@"superlayer" attribute:kCAConstraintHeight scale:0.90 offset:0.0],
        nil
    ];
    [rootLayer insertSublayer:floorLayer atIndex:0];
    
    listOfLayersInOrder = [[NSMutableArray alloc] initWithObjects:[NSMutableArray array], nil];
    layersByID = [[NSMutableDictionary alloc] init];

    // Create our layout manager, for now
    floorLayerLayoutManagerClass = [StadiumLayoutManager class];
    if (floorLayerLayoutManagerClass && !floorLayer.layoutManager) {
        [self setFloorLayerLayoutManagerClass:floorLayerLayoutManagerClass];
    }
    
    hoverPlayLayer = [HoverPlayLayer layer];
    hoverPlayLayer.hidden = YES;
    [rootLayer addSublayer:hoverPlayLayer];
    [hoverPlayLayer bind:@"hoveredMovie" toObject:self withKeyPath:@"hoveredMovie" options:nil];
    [self setHoveredMovie:nil];

    [self _restartMouseTracking];
}

- (void) dealloc
{
    [self cancelHoverTimer];
    [layersByID release];
    [listOfLayersInOrder release];
    [hoverPlayLayer release];
    [super dealloc];
}

- (void) setFloorLayerLayoutManagerClass:(Class)class
{
    floorLayerLayoutManagerClass = class;
    
    if (floorLayer) {
        id<MultiplexLayoutManager> layoutManager = [[class alloc] initWithManagingLayer:floorLayer];
        [floorLayer setLayoutManager:layoutManager];
        [layoutManager release];
    }
}

- (void) setContent:(id)_content
{
    if (content != _content) {
        NSAssert([_content isKindOfClass:[NSArrayController class]], @"content must be of type NSArrayController.");
        if (content) {
            [content removeObserver:self forKeyPath:@"arrangedObjects"];
            [content removeObserver:self forKeyPath:@"content.@count"];
            [content release];
        }
        if (_content) {
            [_content addObserver:self forKeyPath:@"arrangedObjects" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
            [_content addObserver:self forKeyPath:@"content.@count" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
            [_content retain];
        }
        content = _content;
    }
}

- (void) setHoveredMovie:(Movie*)movie
{
    if (movie != hoveredMovie) {
        [hoveredMovie release];
        hoveredMovie = movie;
        hoverPlayLayer.hidden = YES;
    }
    hoveredMovie = [movie retain];
    [self cancelHoverTimer];

    if (movie) {
        /*
        MovieLayer* movieLayer = [layersByID objectForKey:hoveredMovie.objectID];

        hoverHighlightLayer.hidden = NO;
        hoverHighlightLayer.anchorPoint = movieLayer.anchorPoint;
        hoverHighlightLayer.bounds = CGRectInset(movieLayer.bounds, 20, 20);
        hoverHighlightLayer.position = movieLayer.position;
        hoverHighlightLayer.zPosition = movieLayer.zPosition  1;
        hoverHighlightLayer.transform = movieLayer.transform;
        */
        hoverTimer = [[NSTimer scheduledTimerWithTimeInterval:0.75 target:self selector:@selector(hoverTimerTicked:) userInfo:nil repeats:NO] retain];
    }
}


- (void) setFrameSize:(NSSize)frameSize
{
    [super setFrameSize:frameSize];
    [self _restartMouseTracking];
    //[floorLayer setNeedsLayout];
}

- (void) mouseDown:(NSEvent*)theEvent
{
    if (!hoverPlayLayer.hidden) {
        CGPoint p = NSPointToCGPoint([self convertPoint:[theEvent locationInWindow] fromView:nil]);
        CALayer *layer = [hoverPlayLayer hitTest:p];
        if (layer && [layer isKindOfClass:[ButtonLayer class]]) {
            hoverPlayLayer.isMouseDown = YES;
        }
    }
}

- (void) mouseUp:(NSEvent*)theEvent
{
    hoverPlayLayer.isMouseDown = NO;
    CGPoint p = NSPointToCGPoint([self convertPoint:[theEvent locationInWindow] fromView:nil]);
    CALayer* playButtonLayer = [hoverPlayLayer hitTest:p];
    if ([theEvent clickCount] == 2) {
        
        MovieLayer* movieLayer = [self movieLayerForPoint:p];
        if (movieLayer) {
            Movie* movie = [movieLayer movie];
            [content setSelectionIndex:[[content arrangedObjects] indexOfObjectIdenticalTo:movie]];
        }
        
        hoverPlayLayer.hidden = YES;
        [self cancelHoverTimer];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MultiplexShowMovieDialog" object:nil];
    } else if (playButtonLayer) {
        if ([playButtonLayer isKindOfClass:[ButtonLayer class]]) {
            [content setSelectedObjects:[NSArray arrayWithObject:hoveredMovie]];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"MultiplexPlayButtonClicked" object:nil];
        }        
    }
}

- (void) mouseMoved:(NSEvent*)theEvent
{
    CGPoint position = NSPointToCGPoint([self convertPoint:[theEvent locationInWindow] fromView:nil]);
    MovieLayer* movieLayer = [self movieLayerForPoint:position];
    Movie* movie = movieLayer.movie;

    if (hoverPlayLayer.hidden) {
        CGPoint pMove;
        float pY = position.y - hoverPlayLayer.bounds.size.height + 10.0;
        
        if (position.x + hoverPlayLayer.bounds.size.width < [[self window] frame].size.width) {
            [hoverPlayLayer putLayersIntoDefaultPosition];
            pMove = CGPointMake(position.x - 20.0, pY);
        }
        else {
            [hoverPlayLayer putLayersIntoAlternatePosition];
            pMove = CGPointMake(position.x - hoverPlayLayer.bounds.size.width + 20.0, pY);
        }
        
        [hoverPlayLayer setPosition:pMove];
    }

    if ( movie == hoveredMovie || [hoverPlayLayer hitTest:position]) {
        return;
    }
    else {
        [floorLayer.layoutManager setHoveredMovieLayer:movieLayer];
        [self setHoveredMovie:movie];
    }
}

- (void) mouseExited:(NSEvent*)theEvent
{
    [self setHoveredMovie:nil];
}

- (BOOL) acceptsFirstResponder
{
    return YES;
}

@end


#pragma mark -
@implementation MainView (Private)

- (void) _restartMouseTracking
{
    if (mouseTrackingArea) {
        [self removeTrackingArea:mouseTrackingArea];
        [mouseTrackingArea release];
        mouseTrackingArea = nil;
    }
    mouseTrackingArea = [[NSTrackingArea alloc] initWithRect:[self frame] options:(NSTrackingActiveInKeyWindow | NSTrackingInVisibleRect | NSTrackingMouseMoved | NSTrackingMouseEnteredAndExited) owner:self userInfo:nil];
    [self addTrackingArea:mouseTrackingArea];    
}

- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    if ([@"content.@count" isEqualToString:keyPath]) {
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

            [((id<MultiplexLayoutManager>)floorLayer.layoutManager) setListOfLayersInOrder:listOfLayersInOrder];
            [floorLayer setNeedsLayout];
        }
    } else if ([@"arrangedObjects" isEqualToString:keyPath]) {
        NSArray* arrangedObjects = [object arrangedObjects];
        [((id<MultiplexLayoutManager>)floorLayer.layoutManager) setListOfArrangedObjects:arrangedObjects];
        
        [self setHoveredMovie:nil];
        
        int count = [arrangedObjects count];
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

        [((id<MultiplexLayoutManager>)floorLayer.layoutManager) setListOfLayersInOrder:listOfLayersInOrder];
        [floorLayer setNeedsLayout];
    }
}

- (MovieLayer*) movieLayerForPoint:(CGPoint)p
{
    CALayer* layer = [floorLayer hitTest:p];
    while (layer) {
        if ([layer isKindOfClass:[MovieLayer class]]) {
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
        [CATransaction setValue:[NSNumber numberWithFloat:0.25] forKey:kCATransactionAnimationDuration];
        hoverPlayLayer.hidden = NO;
        [CATransaction commit];
    }
}

@end

static const CGFloat W = 280.0;
static const CGFloat H = 400.0;

#pragma mark -
@implementation MainView (LayerStuff)

- (MovieLayer*) newLayerForMovie:(Movie*)movie
{
    MovieLayer* layer = [MovieLayer layerWithMovie:movie];
    layer.frame = CGRectMake(0.0, 0.0, W, H);
    layer.position = CGPointZero;
    return layer;
}

@end
