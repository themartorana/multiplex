#import "MainView.h"
#import "ApplicationController.h"
#import "Movie.h"
#import "MovieLayer.h"
#import "ButtonLayer.h"
#import "BoxArt.h"
#import "MultiplexColorFactory.h"
#import "StadiumLayoutManager.h"
#import "LayerBackedButtonView.h"
#import "ApplicationResources.h"
#import "DrawerView.h"
#import "HoverInfoView.h"
#import "MultiplexDefaults.h"

#import <Toolkit/Toolkit.h>
#import <QuartzCore/QuartzCore.h>

#define DiscSimplePboardType @"DiscSimplePboardType"

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
- (void) _selectMovieLayerApproved:(MovieLayer*)movieLayer;
@end

@implementation MainView

@synthesize content;
@synthesize hoveredMovie;
@synthesize floorLayerLayoutManagerClass;
@synthesize layersByID;

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
    [applicationController bind:@"hoveredMovie" toObject:self withKeyPath:@"hoveredMovie" options:nil];
    
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
    NSString* userDefaultsKey = kMultiplexDrawerIsClosedLayoutManagerClass;
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
    [layoutManager release], layoutManager = nil;
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
    //[layoutManager setShouldShowSelectedMovieHighlight:[drawerView isOpen]];
    [layoutManager setShouldShowSelectedMovieHighlight:YES];
    [layoutManager layoutSublayersOfLayer:floorLayer];
}

- (void) restartHoverTimer
{
    [self _cancelHoverTimer];
    if (hoveredMovie && 
        ![drawerView isOpen] && 
        [[[NSUserDefaults standardUserDefaults] objectForKey:@"HoverTooltipEnabled"] boolValue]) {
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
    //[self restartHoverTimer];
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
    MovieLayer* ml = [layersByID objectForKey:[[applicationController selectedMovie] objectID]];
    
    if (ml != selectedMovieLayer) {
        selectedMovieLayer = ml;
    }
    
    if (selectedMovieLayer) {
        [floorLayer setNeedsLayout];
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

- (void) setNoSelectedMovieLayer
{
    selectedMovieLayer = nil;
    [layoutManager setSelectedMovieLayer:nil];
    [layoutManager layoutSublayersOfLayer:floorLayer];
}

- (void) performClickOpenInfo:(MovieLayer*)movieLayer
{
    if (movieLayer) {
        // Ask the application controller if we're allowed to do this
        NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:@selector(_selectMovieLayerApproved:)]];
        [invocation setTarget:self];
        [invocation setSelector:@selector(_selectMovieLayerApproved:)];
        [invocation retainArguments];
        [invocation setArgument:&movieLayer atIndex:2];
        [applicationController approveMovieSelectionClick:invocation forMovieLayer:movieLayer];
    } 
}

- (void) performClickPlaysMovie:(MovieLayer*)movieLayer
{
    NSNotification* n = [NSNotification notificationWithName:@"MultiplexPlayMovie" object:movieLayer.movie];
    [[NSNotificationCenter defaultCenter] postNotification:n];
}

- (void) mouseDragged:(NSEvent*)theEvent
{
    [hoverTimer invalidate], [hoverTimer release], hoverTimer = nil;
    [hoverInfoView setHidden:YES];
    
    if (!hoveredMovie || ![applicationController selectedMovie] || ![applicationController isDrawerViewOpen])
        return;
    
    if (hoveredMovie == applicationController.selectedMovie)
        return;
    
    // Notify
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MovieDragInitiated" object:nil];
    
    NSPasteboard* pb = [NSPasteboard pasteboardWithName:NSDragPboard];
    [pb declareTypes:[NSArray arrayWithObject:DiscSimplePboardType] owner:self];
    [pb setData:[NSData data] forType:DiscSimplePboardType];
    
    NSImage* image = nil;
    CGImageRef cgImage = hoveredMovie.boxArt.image;
    if (cgImage) {
        // Use the box art
        CGSize size = CGSizeMake(100.0, 140.7);
        image = [[NSImage alloc] initWithSize:NSSizeFromCGSize(size)];
        [image lockFocus];
        CGContextRef c = [[NSGraphicsContext currentContext] graphicsPort];
        CGContextSetAlpha(c, 0.5);
        CGContextDrawImage(c, CGRectMake(0, 0, 100.0, 140.7), cgImage);
        CGContextSetAlpha(c, 1.0);
        [image unlockFocus];
    }
    if (!image) {
        // Do it up generic disc style
        CGSize size = CGSizeMake(100.0, 100.0);
        image = [[NSImage alloc] initWithSize:NSSizeFromCGSize(size)];
        [image lockFocus];
        CGContextRef c = [[NSGraphicsContext currentContext] graphicsPort];
        CGContextSetAlpha(c, 0.5);
        
        NSData* data = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForImageResource:@"disc-dvd-sm.png"]];
        CFDataRef imgData = (CFDataRef)data;
        CGDataProviderRef imgDataProvider = CGDataProviderCreateWithCFData(imgData);
        CGImageRef discImage = CGImageCreateWithPNGDataProvider(imgDataProvider, NULL, true, kCGRenderingIntentDefault);
        
        CGContextDrawImage(c, CGRectMake(0, 0, 100.0, 100.0), discImage);
        CGContextSetAlpha(c, 1.0);
        [image unlockFocus];

        CFRelease(imgDataProvider);
        CFRelease(discImage);
    }
    
    // Create the offset
    NSSize imageSize = [image size];
    NSPoint mousePoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    NSPoint imagePoint = NSMakePoint(mousePoint.x - (imageSize.width / 2.0), mousePoint.y - (imageSize.height / 2.0));
    
    [self dragImage:image 
                 at:imagePoint
             offset:NSMakeSize(0, 0)
              event:theEvent 
         pasteboard:pb
             source:self 
          slideBack:YES];
    
    [image release];
}

- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MovieDragCompleted" object:nil];
    //[super draggedImage:anImage endedAt:aPoint operation:operation];
}

- (void) mouseUp:(NSEvent*)theEvent
{
    CGPoint p = NSPointToCGPoint([self convertPoint:[theEvent locationInWindow] fromView:nil]);
    
    MovieLayer* movieLayer = [self movieLayerForPoint:p];
    if (![[listOfMoviesInOrder objectAtIndex:[listOfMoviesInOrder count] - 1] containsObject:movieLayer.movie]) {
        movieLayer = nil;
        return;
    }

    BOOL singleClickLaunchesMovie = [[MultiplexDefaults standardUserDefaults] boolForKey:@"SingleClickLaunchesMovie"];
    
    // Stupid logic, thinks it's so good.
    if ([drawerView isOpen]) {
        [self performClickOpenInfo:movieLayer];
    }
    else if (1 == [theEvent clickCount] && singleClickLaunchesMovie) {
        [self performSelector:@selector(performClickPlaysMovie:) withObject:movieLayer afterDelay:[MultiplexDefaults doubleClickDelayTimeInterval]];
    }
    else if (2 == [theEvent clickCount] && singleClickLaunchesMovie) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [self performClickOpenInfo:movieLayer];
    }
    else if (1 == [theEvent clickCount] && !singleClickLaunchesMovie) {
        [self performSelector:@selector(performClickOpenInfo:) withObject:movieLayer afterDelay:[MultiplexDefaults doubleClickDelayTimeInterval]];
    }
    else if (2 == [theEvent clickCount] && !singleClickLaunchesMovie) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [self performClickPlaysMovie:movieLayer];
    }
}

- (void) rightMouseDown:(NSEvent*)theEvent
{
    [hoverTimer invalidate];
    [hoverTimer release], hoverTimer = nil;
    [hoverInfoView setHidden:YES];
    
    CGPoint position = NSPointToCGPoint([self convertPoint:[theEvent locationInWindow] fromView:nil]);
    MovieLayer* movieLayer = [self movieLayerForPoint:position];
    NSLog(NSStringFromPoint(NSPointFromCGPoint(position)));
    if (movieLayer) {
        [layoutManager setShouldShowHoveredMovieHighlight:YES];
        self.hoveredMovie = movieLayer.movie;
        [floorLayer setNeedsLayout];
    }
        
    //[super rightMouseDown:theEvent];
}

- (void) rightMouseUp:(NSEvent*)theEvent
{
    if (self.hoveredMovie) {
        [NSMenu popUpContextMenu:[self menu] withEvent:theEvent forView:self];        
    }
}

- (void) mouseMoved:(NSEvent*)theEvent
{
    CGPoint position = NSPointToCGPoint([self convertPoint:[theEvent locationInWindow] fromView:nil]);
    MovieLayer* movieLayer = [self movieLayerForPoint:position];
    Movie* movie = movieLayer.movie;
    
    //NSLog(NSStringFromPoint(NSPointFromCGPoint(position)));

    if (movieLayer) {
        [layoutManager setShouldShowHoveredMovieHighlight:YES];
    }
    
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

- (void) keyDown:(NSEvent*)event
{
    NSLog(@"Key pressed: %d", [event keyCode]);
    
    NSArray* listOfLayersInOrder = [[self _listOfLayersInOrder] lastObject];
    
    int index = [listOfLayersInOrder indexOfObject:selectedMovieLayer];
    
    [layoutManager setShouldShowHoveredMovieHighlight:NO];
    
    switch ([event keyCode]) {
        case 36:
        case 76:
            // RETURN or ENTER
            if (selectedMovieLayer) {
                //[applicationController showMovieDetailAndSelectHomeTabForMovie:[selectedMovieLayer movie]];
                [self performClickPlaysMovie:selectedMovieLayer];
            }
            return;
            break;
        
        case 48:
            // TAB
            // Determine if the next key views are set properly
            [[self window] selectNextKeyView:self];
            return;
            break;
            
        case 53:
            // ESC
            if ([applicationController isInFullScreen]) {
                [applicationController toggleFullScreen:self];
            }
            return;
            break;
    }
    
    MovieLayer* nextMovieLayer = nil;
    
    if (selectedMovieLayer && [listOfLayersInOrder count]) {
        switch ([event keyCode]) {
            case 123:
                // RIGHT ARROW
                if (index > 0) {
                    nextMovieLayer = [listOfLayersInOrder objectAtIndex:index - 1];
                }
                else {
                    nextMovieLayer = [listOfLayersInOrder lastObject];
                }
                break;
                
            case 124:
                // LEFT ARROW
                if ((index + 1) != [listOfLayersInOrder count]) {
                    nextMovieLayer = [listOfLayersInOrder objectAtIndex:index + 1];
                }
                else {
                    nextMovieLayer = [listOfLayersInOrder objectAtIndex:0];
                }
                break;
                
            case 125:
                // UP ARROW
                if (selectedMovieLayer.upLayer) {
                    nextMovieLayer = selectedMovieLayer.upLayer;
                }
                break;
                
            case 126:
                // DOWN ARROW
                if (selectedMovieLayer.downLayer) {
                    nextMovieLayer = selectedMovieLayer.downLayer;
                }
                break;
                
            default:
                break;
        }
    }
    else {
        nextMovieLayer = [listOfLayersInOrder objectAtIndex:0];
    }
    
    // Make sure it gets selected
    if (nextMovieLayer) {
        selectedMovieLayer = nextMovieLayer;
    }
    
    if (nextMovieLayer && [nextMovieLayer movie]) {
        if ([applicationController isDrawerViewOpen]) {
            [self performClickOpenInfo:nextMovieLayer];
        }
        else {
            [content setSelectedObjects:[NSArray arrayWithObject:[nextMovieLayer movie]]];
            
            
            // Set the hovered layer to the selected layer
            [self setHoveredMovie:[nextMovieLayer movie]];
        }
    }

    [floorLayer setNeedsLayout];
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
        [mouseTrackingArea release], mouseTrackingArea = nil;
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
        //[newListOfMoviesInOrder addObject:[arrangedObjects copy]];
        [newListOfMoviesInOrder addObject:arrangedObjects];
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
        
        // Cleanup
        //for (NSManagedObjectID* objectID in  
    }
    for (NSManagedObjectID* objectID in keysOfLayersToDelete) {
        MovieLayer* layerToDelete = [layersByID objectForKey:objectID];
        layerToDelete.movie = nil;
        [layerToDelete removeFromSuperlayer];
        [layersByID removeObjectForKey:objectID];
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

- (void) _selectMovieLayerApproved:(MovieLayer*)movieLayer
{
    selectedMovieLayer = movieLayer;
    
    [content setSelectedObjects:[NSArray arrayWithObject:[movieLayer movie]]];
    [hoverInfoView setHidden:YES];
    [self _cancelHoverTimer];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MultiplexShowMovieDialog" object:nil];
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
