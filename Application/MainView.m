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
- (MovieLayer*) _newLayerForMovie:(Movie*)movie;
@end

@interface MainView (Private)
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context;
- (void) _cancelHoverTimer;
- (NSArray*) _listOfLayersInOrder;
- (MovieLayer*) _movieLayerForPoint:(CGPoint)p;
- (void) _hoverTimerTicked:(NSTimer*)timer;
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
    floorLayer.layoutManager = self;
    floorLayer.constraints = [NSArray arrayWithObjects:
        [CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY],
        [CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX],
        [CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth scale:0.95 offset:0.0],
        [CAConstraint constraintWithAttribute:kCAConstraintHeight relativeTo:@"superlayer" attribute:kCAConstraintHeight],
        nil
    ];
    [rootLayer insertSublayer:floorLayer atIndex:0];
    
    [self setFloorLayerLayoutManagerClass:[StadiumLayoutManager class]];
    layersByID = [[NSMutableDictionary alloc] init];
    
    hoverPlayLayer = [HoverPlayLayer layer];
    hoverPlayLayer.hidden = YES;
    [rootLayer addSublayer:hoverPlayLayer];
    [hoverPlayLayer bind:@"hoveredMovie" toObject:self withKeyPath:@"hoveredMovie" options:nil];

    [self _restartMouseTracking];
}

- (void) dealloc
{
    [self _cancelHoverTimer];
    [layersByID release];
    [listOfMoviesInOrder release];
    [hoverPlayLayer release];
    [super dealloc];
}

- (void) setFloorLayerLayoutManagerClass:(Class)class
{
    floorLayerLayoutManagerClass = class;
    if (layoutManager) {
        [layoutManager clearManagingLayerOfExtras];
    }
    layoutManager = [[class alloc] initWithManagingLayer:floorLayer];
    if (content && [[content arrangedObjects] count] > 0) {
        id a = [content valueForKeyPath:@"selection.self"];
        if ([a isKindOfClass:[Movie class]]) {
            [layoutManager setSelectedMovie:(Movie*)a];
        }
    }
    [floorLayer setNeedsLayout];
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

- (void) layoutSublayersOfLayer:(CALayer*)layer
{
    NSAssert(layer == floorLayer, @"wtf?");
    [layoutManager setListOfLayersInOrder:[self _listOfLayersInOrder]];
    [layoutManager layoutSublayersOfLayer:floorLayer];
}

- (void) restartHoverTimer
{
    [self _cancelHoverTimer];
    if (hoveredMovie) {
        hoverTimer = [[NSTimer scheduledTimerWithTimeInterval:0.75 target:self selector:@selector(_hoverTimerTicked:) userInfo:nil repeats:NO] retain];
    }
}

- (void) setHoveredMovie:(Movie*)_hoveredMovie
{
    if (_hoveredMovie != hoveredMovie) {
        [hoveredMovie release];
        hoveredMovie = [_hoveredMovie retain];
        hoverPlayLayer.hidden = YES;
        [layoutManager setHoveredMovieLayer:[layersByID objectForKey:_hoveredMovie.objectID]];
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

    MovieLayer* movieLayer = [self _movieLayerForPoint:p];
    if (![[listOfMoviesInOrder objectAtIndex:[listOfMoviesInOrder count] - 1] containsObject:movieLayer.movie]) {
        movieLayer = nil;
    }
    if (movieLayer && ([layoutManager changesSelectionOnSingleClick] && [theEvent clickCount] == 1) ||
        (![layoutManager changesSelectionOnSingleClick] && [theEvent clickCount] == 2)) {
        
        [content setSelectedObjects:[NSArray arrayWithObject:[movieLayer movie]]];
        hoverPlayLayer.hidden = YES;
        [self _cancelHoverTimer];
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
    MovieLayer* movieLayer = [self _movieLayerForPoint:position];
    Movie* movie = movieLayer.movie;
    if (movie && ![[content arrangedObjects] containsObject:movie]) {
        movie = nil;
    }
    
    if (movie != hoveredMovie && ![hoverPlayLayer hitTest:position]) {
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
            [layoutManager setSelectedMovie:nil];
        } else {
            [layoutManager setSelectedMovie:selection];
        }
    } else if ([@"content.@count" isEqualToString:keyPath]) {
        [listOfMoviesInOrder autorelease];
        listOfMoviesInOrder = [[NSArray alloc] initWithObjects:[[content arrangedObjects] copy], nil];
        [self setHoveredMovie:nil];
        [floorLayer setNeedsLayout];
    } else if ([@"arrangedObjects" isEqualToString:keyPath]) {
        [listOfMoviesInOrder autorelease];
        NSMutableArray* newListOfMoviesInOrder = [listOfMoviesInOrder mutableCopy];
        NSArray* arrangedObjects = [object arrangedObjects];
        int count = [arrangedObjects count];
        for (NSArray* moviesInOrder in [listOfMoviesInOrder reverseObjectEnumerator]) {
            if ([moviesInOrder count] > count) {
                break;
            }
            [newListOfMoviesInOrder removeLastObject];
        }
        [newListOfMoviesInOrder addObject:[arrangedObjects copy]]; 
        listOfMoviesInOrder = newListOfMoviesInOrder;
        [self setHoveredMovie:nil];
        [floorLayer setNeedsLayout];
    }
}

- (NSArray*) _listOfLayersInOrder
{
    NSMutableSet* keysOfLayersToDelete = [NSMutableSet setWithArray:[layersByID allKeys]];
    NSMutableArray* listOfLayersInOrder = [NSMutableArray arrayWithCapacity:[listOfMoviesInOrder count]];
    for (NSArray* movies in listOfMoviesInOrder) {
        NSMutableArray* layers = [NSMutableArray arrayWithCapacity:[movies count]];
        for (Movie* movie in movies) {
            NSManagedObjectID* objectID = [movie objectID];
            MovieLayer* layer = [layersByID objectForKey:objectID];
            if (!layer) {
                layer = [self _newLayerForMovie:movie];
                [floorLayer addSublayer:layer];
                [layersByID setObject:layer forKey:objectID];
            } else {
                [keysOfLayersToDelete removeObject:objectID];
            }
            [layers addObject:layer];
        }
        [listOfLayersInOrder addObject:layers];
    }
    for (NSManagedObjectID* objectID in keysOfLayersToDelete) {
        [[layersByID objectForKey:objectID] removeFromSuperlayer];
    }
    
    return listOfLayersInOrder;
}

- (MovieLayer*) _movieLayerForPoint:(CGPoint)p
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

- (void) _cancelHoverTimer 
{
    if (hoverTimer) @synchronized (hoverTimer) {
        [hoverTimer invalidate];
        [hoverTimer release];
        hoverTimer = nil;
    }
}

- (void) _hoverTimerTicked:(NSTimer*)timer
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

- (MovieLayer*) _newLayerForMovie:(Movie*)movie
{
    MovieLayer* layer = [MovieLayer layerWithMovie:movie];
    layer.frame = CGRectMake(0.0, 0.0, W, H);
    layer.position = CGPointZero;
    return layer;
}

@end
