#import "MainView.h"
#import "ApplicationController.h"
#import "Movie.h"
#import "MovieLayer.h"
#import "ButtonLayer.h"
#import "MultiplexColorFactory.h"
#import "StadiumLayoutManager.h"
#import "LayerBackedButtonView.h"
#import "ApplicationResources.h"
#import "DrawerView.h"
#import "HoverInfoView.h"

#import <Toolkit/Toolkit.h>
#import <QuartzCore/QuartzCore.h>

NSString* const kMultiplexDrawerIsOpenLayoutManagerClass = @"MultiplexDrawerIsOpenLayoutManagerClass";
NSString* const kMultiplexDrawerIsClosedLayoutManagerClass = @"MultiplexDrawerIsClosedLayoutManagerClass";

@interface MainView (LayerStuff)
- (MovieLayer*) _newLayerForMovie:(Movie*)movie;
@end

@interface MainView (Private)
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context;
- (void) _cancelHoverTimer;
- (NSArray*) _listOfLayersInOrder;
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
    
    Class c = NSClassFromString([[NSUserDefaults standardUserDefaults] objectForKey:kMultiplexDrawerIsClosedLayoutManagerClass]);
    if (!c) {
        c = [StadiumLayoutManager class];        
    }
    [self setFloorLayerLayoutManagerClass:c];
    
    layersByID = [[NSMutableDictionary alloc] init];
    
    [hoverInfoView bind:@"movie" toObject:self withKeyPath:@"hoveredMovie" options:nil];
    
    [drawerView addObserver:self forKeyPath:@"isOpen" options:NSKeyValueObservingOptionNew context:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playCatchUpToSelectedMovie:) name:@"MultiplexShowMovieDialog" object:nil];
    
    [self _restartMouseTracking];
}

- (void) dealloc
{
    [self _cancelHoverTimer];
    [layersByID release];
    [listOfMoviesInOrder release];
    [super dealloc];
}

- (void) setFloorLayerLayoutManagerClass:(Class)class
{
    // Figure out what state we're in and which key to use
    NSString* userDefaultsKey = kMultiplexDrawerIsClosedLayoutManagerClass;;
    if ([drawerView isOpen]) {
        userDefaultsKey = kMultiplexDrawerIsOpenLayoutManagerClass;
    }
    
    // If nil is passed, try using the one in the user defaults
    if (!class) {
        // Try to get the class
        class = [[NSUserDefaults standardUserDefaults] objectForKey:userDefaultsKey];
        
        if (!class) {
            return;
        }
    }
    
    // Save the class
    floorLayerLayoutManagerClass = class;
    
    [[NSUserDefaults standardUserDefaults] setObject:NSStringFromClass(floorLayerLayoutManagerClass) forKey:userDefaultsKey];
    
    if (layoutManager) {
        [layoutManager clearManagingLayerOfExtras];
    }
    layoutManager = [[class alloc] initWithManagingLayer:floorLayer];
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
    [layoutManager setSelectedMovieLayer:selectedMovieLayer];
    [layoutManager setShouldShowSelectedMovieHighlight:[drawerView isOpen]];
    [layoutManager layoutSublayersOfLayer:floorLayer];
}

- (void) restartHoverTimer
{
    [self _cancelHoverTimer];
    if (hoveredMovie && ![drawerView isOpen]) {
        hoverTimer = [[NSTimer scheduledTimerWithTimeInterval:0.75 target:self selector:@selector(_hoverTimerTicked:) userInfo:nil repeats:NO] retain];
    }
}

- (void) setHoveredMovie:(Movie*)_hoveredMovie
{
    if (_hoveredMovie) {
        if ([NSCursor currentCursor] != [NSCursor pointingHandCursor]) {
            [[NSCursor pointingHandCursor] push];    
        }
    }
    else {
        [NSCursor pop];
    }
    
    if (_hoveredMovie != hoveredMovie) {
        [hoveredMovie release];
        hoveredMovie = [_hoveredMovie retain];
        [hoverInfoView setHidden:YES];
        [layoutManager setHoveredMovieLayer:[layersByID objectForKey:_hoveredMovie.objectID]];
    }
    [self restartHoverTimer];
}

- (void) setFrame:(NSRect)frame
{
    // SUPER HACK! Helps with full-screen
    [super setFrame:frame];
    [[self layer] setFrame:NSRectToCGRect(frame)];
}

- (void) setFrameSize:(NSSize)frameSize
{
    [super setFrameSize:frameSize];
    [self _restartMouseTracking];
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

- (void) resetCurrentlySelectedMovieLayer
{
    if (selectedMovieLayer) {
        [selectedMovieLayer setNeedsDisplay];
    }
}

- (void) playCatchUpToSelectedMovie:(NSNotification*)notification
{
    // It's possible that someone else has determined a movie to be 
    // selected and openend in the info view.  If that's 
    // correct, we need to play a little catch up.
    id obj = [notification object];
    if (obj && [obj isKindOfClass:[NSManagedObject class]]) {
        NSEntityDescription* movieEntity = [NSEntityDescription entityForName:@"Movie" inManagedObjectContext:[applicationController appManagedObjectContext]];
        if ([[(NSManagedObject*)obj entity] isKindOfEntity:movieEntity]) {
            selectedMovieLayer = [layersByID objectForKey:((Movie*)obj).objectID];
        }
    }
}

// Not necessary since the change to a NSView
/*- (void) mouseDown:(NSEvent*)theEvent
{
    if (![hoverInfoView isHidden]) {
        CGPoint p = NSPointToCGPoint([self convertPoint:[theEvent locationInWindow] fromView:nil]);
        CALayer *layer = [hoverInfoView hitTest:p];
        if (layer && [layer isKindOfClass:[ButtonLayer class]]) {
            hoverInfoView.isMouseDown = YES;
        }
    }
}*/

- (void) mouseUp:(NSEvent*)theEvent
{
    CGPoint p = NSPointToCGPoint([self convertPoint:[theEvent locationInWindow] fromView:nil]);
    /*hoverInfoView.isMouseDown = NO;
    CALayer* playButtonLayer = [hoverInfoView hitTest:p];

    if (playButtonLayer) {
        if ([playButtonLayer isKindOfClass:[ButtonLayer class]]) {
            [content setSelectedObjects:[NSArray arrayWithObject:hoveredMovie]];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"MultiplexPlayButtonClicked" object:nil];
        }  
        
        return;
    }*/

    // This was the else for double-click with drawer open.  Leaving in
    // since the move to single-click is experimental at this time.
    //else if (movieLayer && ([drawerView isOpen] && [theEvent clickCount] == 1) ||
    //    (![drawerView isOpen] && [theEvent clickCount] == 2)) {
    
    MovieLayer* movieLayer = [self movieLayerForPoint:p];
    if (![[listOfMoviesInOrder objectAtIndex:[listOfMoviesInOrder count] - 1] containsObject:movieLayer.movie]) {
        movieLayer = nil;
    }
    
    else if (movieLayer) {
        
        // Ask the application controller if we're allowed to do this
        if ([applicationController canSwitchDrawerControllers])
        {
            selectedMovieLayer = movieLayer;
            
            [content setSelectedObjects:[NSArray arrayWithObject:[movieLayer movie]]];
            [hoverInfoView setHidden:YES];
            [self _cancelHoverTimer];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"MultiplexShowMovieDialog" object:nil];
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
    
    if (movie != hoveredMovie && ![hoverInfoView hitTest:NSPointFromCGPoint(position)]) {
        [self setHoveredMovie:movie];
        [self restartHoverTimer];
    }
    
    if ([hoverInfoView isHidden]) {
        if (position.x + [hoverInfoView bounds].size.width < [self frame].size.width) {
            [hoverInfoView setInFlipPosition:NO];
        } else {
            [hoverInfoView setInFlipPosition:YES];
        }
    }
}

- (void) mouseExited:(NSEvent*)theEvent
{
    [self setHoveredMovie:nil];
}

#if 0
- (void) keyDown:(NSEvent*)event
{
    switch ([event keyCode]) {
        case 123:
            if (selectedMovieLayer.leftLayer) {
                selectedMovieLayer = selectedMovieLayer.leftLayer;
            }
            break;
            
        case 124:
            if (selectedMovieLayer.rightLayer) {
                selectedMovieLayer = selectedMovieLayer.rightLayer;
            }
            break;
            
        case 125:
            if (selectedMovieLayer.upLayer) {
                selectedMovieLayer = selectedMovieLayer.upLayer;
            }
            break;
        
        case 126:
            if (selectedMovieLayer.downLayer) {
                selectedMovieLayer = selectedMovieLayer.downLayer;
            }
            break;
            
        default:
            break;
    }
    
    if (selectedMovieLayer && [selectedMovieLayer movie]) {
        [content setSelectedObjects:[NSArray arrayWithObject:[selectedMovieLayer movie]]];
    }

    [floorLayer setNeedsLayout];
}
#endif

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
    } else if ([@"isOpen" isEqualToString:keyPath]) {
        [layoutManager setShouldShowSelectedMovieHighlight:[drawerView isOpen]];
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
        if ([hoverInfoView isHidden])
            [hoverInfoView setHidden:NO];
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
    
    //if (!selectedMovieLayer) {
    //    selectedMovieLayer = layer;
    //}
    
    return layer;
}

@end
