#import "MainView.h"
#import "Movie.h"
#import "MovieLayer.h"
#import "ButtonLayer.h"
#import "MultiplexColorFactory.h"
#import "StadiumLayoutManager.h"
#import "LayerBackedButtonView.h"
#import "ApplicationResources.h"

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
    floorLayer.constraints = [NSArray arrayWithObjects:
        [CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY],
        [CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX],
        [CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth scale:0.95 offset:0.0],
        [CAConstraint constraintWithAttribute:kCAConstraintHeight relativeTo:@"superlayer" attribute:kCAConstraintHeight],
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
        
        if (floorLayer.layoutManager) {
            [floorLayer.layoutManager clearManagingLayerOfExtras];
        }
        
        id<MultiplexLayoutManager> layoutManager = [[class alloc] initWithManagingLayer:floorLayer];
        
        [layoutManager setListOfLayersInOrder:listOfLayersInOrder];
        [layoutManager setListOfArrangedObjects:[content arrangedObjects]];
        [floorLayer setLayoutManager:layoutManager];
        [layoutManager release];

        if (content && [[content arrangedObjects] count] > 0) {
            id a = [content valueForKeyPath:@"selection.self"];
            if ([a isKindOfClass:[Movie class]]) {
                [floorLayer.layoutManager setSelectedMovie:(Movie*)a];
            }
        }
        
        [floorLayer setNeedsLayout];
    }
}

- (void) setContent:(id)_content
{
    if (content != _content) {
        NSAssert([_content isKindOfClass:[NSArrayController class]], @"content must be of type NSArrayController.");
        if (content) {
            [content removeObserver:self forKeyPath:@"arrangedObjects"];
            [content removeObserver:self forKeyPath:@"content.@count"];
            [content removeObserver:self forKeyPath:@"selection.self"];
            [content release];
        }
        if (_content) {
            [_content addObserver:self forKeyPath:@"arrangedObjects" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
            [_content addObserver:self forKeyPath:@"content.@count" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
            [_content addObserver:self forKeyPath:@"selection.self" options:NSKeyValueObservingOptionNew context:nil];
            [_content retain];
        }
        content = _content;
    }
}

- (void) restartHoverTimer
{
    [self cancelHoverTimer];
    if (hoveredMovie) {
        hoverTimer = [[NSTimer scheduledTimerWithTimeInterval:0.75 target:self selector:@selector(hoverTimerTicked:) userInfo:nil repeats:NO] retain];
    }
}

- (void) setHoveredMovie:(Movie*)_hoveredMovie
{
    if (_hoveredMovie != hoveredMovie) {
        [hoveredMovie release];
        hoveredMovie = [_hoveredMovie retain];
        hoverPlayLayer.hidden = YES;
    }
    [self restartHoverTimer];
}


- (void) setFrameSize:(NSSize)frameSize
{
    [super setFrameSize:frameSize];
    [self _restartMouseTracking];
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
            [content setSelectedObjects:[NSArray arrayWithObject:[movieLayer movie]]];
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
    if (movie && ![[content arrangedObjects] containsObject:movie]) {
        movie = nil;
    }
    
    if (movie != hoveredMovie && ![hoverPlayLayer hitTest:position]) {
        [floorLayer.layoutManager setHoveredMovieLayer:movieLayer];
        [self setHoveredMovie:movie];
    } else {
        [self restartHoverTimer];
    }
    
    if (hoverPlayLayer.hidden) {
        CGPoint newPosition = CGPointMake(position.x, position.y - hoverPlayLayer.bounds.size.height + 10.0);
        if (position.x + hoverPlayLayer.bounds.size.width < [self frame].size.width) {
            [hoverPlayLayer putLayersIntoDefaultPosition];
            newPosition.x -= 20.0;
        } else {
            [hoverPlayLayer putLayersIntoAlternatePosition];
            newPosition.x -= 20.0 + hoverPlayLayer.bounds.size.width;
        }
        [hoverPlayLayer setPosition:newPosition];
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
    if ([@"selection" isEqualToString:keyPath]) {
        id selection = [change objectForKey:NSKeyValueChangeNewKey];
        if (selection == NSNoSelectionMarker || selection == (id)kCFNull) {
            [floorLayer.layoutManager setSelectedMovie:nil];
        } else {
            [floorLayer.layoutManager setSelectedMovie:selection];
        }
    }
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
        [self setHoveredMovie:nil];
        
        NSArray* arrangedObjects = [object arrangedObjects];
        [((id<MultiplexLayoutManager>)floorLayer.layoutManager) setListOfArrangedObjects:arrangedObjects];
        
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
