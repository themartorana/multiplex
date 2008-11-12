#import "LinearLayoutManager.h"
#import "MultiplexColorFactory.h"
#import "Movie.h"
#import "MovieLayer.h"
#import "ApplicationResources.h"

#import <QuartzCore/QuartzCore.h>
#import <Toolkit/CALayer+IndyHallLabs.h>

@implementation LinearLayoutManager
@synthesize listOfLayersInOrder;

- (id<MultiplexLayoutManagerProtocol>) initWithManagingLayer:(CALayer*)_floorLayer
{
    if (self == [super init]) {
        floorLayer = [_floorLayer retain];
        floorLayer.masksToBounds = NO;
        
        selectedHighlightLayer = [CALayer layer];
        selectedHighlightLayer.borderColor = [MultiplexColorFactory multiplexYellowOrangeAsCGColor];
        selectedHighlightLayer.borderWidth = 10.0;
        selectedHighlightLayer.cornerRadius = 10.0;
        selectedHighlightLayer.hidden = YES;
        [floorLayer addSublayer:selectedHighlightLayer];
        
        hoverHighlightLayer = [CALayer layer];
        hoverHighlightLayer.borderColor = [MultiplexColorFactory multiplexOrange];
        hoverHighlightLayer.borderWidth = 10.0;
        hoverHighlightLayer.cornerRadius = 10.0;
        hoverHighlightLayer.hidden = YES;
        [floorLayer addSublayer:hoverHighlightLayer];
        
        scrollToSelectedMovie = YES;
    }
    
    return self;
}

- (void) dealloc
{
    [floorLayer release];
    
    [super dealloc];
}

- (void) clearManagingLayerOfExtras
{
    [hoverHighlightLayer removeFromSuperlayer];
    [selectedHighlightLayer removeFromSuperlayer];
}

- (void) setListOfLayersInOrder:(NSArray*)_listOfLayersInOrder
{
    if (listOfLayersInOrder) {
        [listOfLayersInOrder release];
        listOfLayersInOrder = nil;
    }
    listOfLayersInOrder = [_listOfLayersInOrder copy];
}

- (void) setShouldShowSelectedMovieHighlight:(BOOL)show
{
    shouldShowHiglightLayer = show;
}

- (void) setSelectedMovieLayer:(MovieLayer*)movieLayer
{
    if (selectedMovieLayer) {
        [selectedMovieLayer release];
        selectedMovieLayer = nil;
    }
    
    selectedMovieLayer = [movieLayer retain];
    
    if (selectedMovieLayer) {
        dontLayoutBecauseOfHighlight = NO;
        scrollToSelectedMovie = YES;        
    } else {
        scrollToSelectedMovie = NO;
        selectedHighlightLayer.hidden = YES;
    }
}

- (void) setHoveredMovieLayer:(MovieLayer*)movieLayer;
{
    [CATransaction begin];
    [CATransaction setValue:[NSNumber numberWithDouble:0.0] forKey:kCATransactionAnimationDuration];
    
    if (movieLayer) {
        dontLayoutBecauseOfHighlight = YES;
        hoverHighlightLayer.hidden = NO;
        hoverHighlightLayer.anchorPoint = movieLayer.anchorPoint;
        hoverHighlightLayer.bounds = CGRectInset(movieLayer.bounds, -20, -20);
        hoverHighlightLayer.position = movieLayer.position;
        hoverHighlightLayer.zPosition = movieLayer.zPosition - 1;
        hoverHighlightLayer.transform = movieLayer.transform;
    } else {
        hoverHighlightLayer.hidden = YES;
    }
    
    [CATransaction commit];
}

static const CGFloat WS = 75.0;
static const CGFloat W = 280.0;
static const CGFloat H = 400.0;
static const CGFloat HS = 75.0;

- (void) layoutSublayersOfLayer:(CALayer*)layoutLayer
{
    // TODO: THERE MUST A BETTER WAY!
    if (dontLayoutBecauseOfHighlight) {
        dontLayoutBecauseOfHighlight = NO;
        return;
    }
    
    NSLog(@"laying out");
    
    [CATransaction begin];
    [CATransaction setValue:[NSNumber numberWithDouble:([[NSApp currentEvent] modifierFlags] & NSShiftKeyMask) ? 3.0 : 0.3] forKey:kCATransactionAnimationDuration];
    
    NSMutableSet* tagged = [NSMutableSet set];
    BOOL hidden = NO;
    for (NSArray* layersInOrder in [listOfLayersInOrder reverseObjectEnumerator]) {
        for (MovieLayer* layer in layersInOrder) {
            if (![tagged containsObject:layer.movie.objectID]) {
                layer.hidden = hidden;
                layer.opaque = YES;
                layer.opacity = 1.0;
                [tagged addObject:layer.movie.objectID];
            }
        }
        hidden = YES;
    }
    
    /*  This base transform sets up the origin (0, 0) to the center of the 
     *  layer along the X and Y axes.
     */
    CATransform3D b = CATransform3DIdentity;
    b = CATransform3DTranslate(b, layoutLayer.bounds.size.width / 2.0, layoutLayer.bounds.size.height / 2.0, 0.0);
    
    if (![listOfLayersInOrder count]) {
        return;
    }
    
    NSArray* layersInOrder = [listOfLayersInOrder objectAtIndex:[listOfLayersInOrder count] - 1];
    CGSize const size = layoutLayer.bounds.size;
    CGFloat columns = [layersInOrder count];
    CGFloat height = (HS + (H + HS));
    CGFloat width = (WS + ((W + WS) * columns));
    BOOL lastWasEmpty = lastWasEmpty = !columns;
    
    CGFloat scrollToPointX = 0.0;
    
    int x = 0;
    MovieLayer* previousLayer = nil;
    for (MovieLayer* layer in layersInOrder) {
        
        [layer clearMoveData];
        previousLayer.rightLayer = layer;
        layer.leftLayer = previousLayer;
        previousLayer = layer;
        
        CGFloat chord = WS + (W / 2.0) + ((W + WS) * x);
        
        CATransform3D t = b;
        t = CATransform3DTranslate(t, 0.0, (H + HS) - (H / 2.0), 0.0);
        t = CATransform3DTranslate(t, chord - (width / 2.0), 0.0, 0.0);
        layer.transform = t;
        
        x++;
        
        if ((MovieLayer*)layer == selectedMovieLayer) {
            scrollToPointX = chord - (width / 2.0);
        }
    }
    
    if (!lastWasEmpty) {
        /*  Add in our scale and perspective...  then throw a little rotational 
         *  "stank" on it.  ;)
         */
        if (selectedMovieLayer && shouldShowHiglightLayer) {
            selectedHighlightLayer.hidden = NO;
            selectedHighlightLayer.anchorPoint = selectedMovieLayer.anchorPoint;
            selectedHighlightLayer.bounds = CGRectInset(selectedMovieLayer.bounds, -20, -20);
            selectedHighlightLayer.position = selectedMovieLayer.position;
            selectedHighlightLayer.zPosition = selectedMovieLayer.zPosition - 1;
            selectedHighlightLayer.transform = selectedMovieLayer.transform;
        } else {
            selectedHighlightLayer.hidden = YES;
        }
        
        CGFloat pScale = size.height / height;
        CATransform3D p = CATransform3DIdentity;
        p = CATransform3DScale(p, pScale, pScale, 1.0);
        p = CATransform3DTranslate(p, 0.0, -height / 2.0, 0.0);
        //p.m34 = 1.0 / -MAX(width, 2000);
        //p = CATransform3DRotate(p, 0.075, 1.0, 0.0, 0.0);
        
        if (scrollToSelectedMovie && selectedMovieLayer && [selectedMovieLayer isKindOfClass:[CALayer class]]) {
            p = CATransform3DTranslate(p, -scrollToPointX, 0.0, 0.0);
        }
        
        layoutLayer.sublayerTransform = p;
    }
    
    [CATransaction commit];
}

@end
