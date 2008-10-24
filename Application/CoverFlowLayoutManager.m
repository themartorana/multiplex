#import "CoverFlowLayoutManager.h"
#import "MultiplexLayoutManager.h"
#import "MovieLayer.h"
#import "Movie.h"
#import "MultiplexColorFactory.h"
#import <Toolkit/Toolkit.h>

@implementation CoverFlowLayoutManager

- (id<MultiplexLayoutManager>) initWithManagingLayer:(CALayer*)layer 
{
    if (self = [super init]) {
        floorLayer = [layer retain];
        //[layer setMasksToBounds:YES];

        selectedHighlightLayer = [[CALayer layer] retain];
        selectedHighlightLayer.borderColor = [MultiplexColorFactory multiplexYellowOrangeAsCGColor];
        selectedHighlightLayer.borderWidth = 10.0;
        selectedHighlightLayer.cornerRadius = 10.0;
        selectedHighlightLayer.hidden = YES;
        [floorLayer addSublayer:selectedHighlightLayer];
        
        hoverHighlightLayer = [[CALayer layer] retain];
        hoverHighlightLayer.borderColor = [MultiplexColorFactory multiplexOrange];
        hoverHighlightLayer.borderWidth = 10.0;
        hoverHighlightLayer.cornerRadius = 10.0;
        hoverHighlightLayer.hidden = YES;
        [floorLayer addSublayer:hoverHighlightLayer];
    }
    
    return self;
}

- (void) dealloc 
{
    if (listOfLayersInOrder) {
        [listOfLayersInOrder release];
    }
    if (arrangedListOfObjects) {
        [arrangedListOfObjects release];
    }
    
    [floorLayer release];
    
    [super dealloc];
}

- (void) clearManagingLayerOfExtras
{
    [hoverHighlightLayer removeFromSuperlayer];
    [selectedHighlightLayer removeFromSuperlayer];
}

- (void) setSelectedMovie:(Movie*)movie
{
    if (selectedMovie) {
        [selectedMovie release];
        selectedMovie = nil;
    }
    
    selectedMovie = [movie retain];
    
    if (selectedMovie) {
        hoverHighlightLayer.hidden = YES;
        scrollToSelectedMovie = YES;        
        [floorLayer setNeedsLayout];
    } else {
        scrollToSelectedMovie = NO;
    }

}

- (void) setHoveredMovieLayer:(MovieLayer*)layer
{
    if (hoveredMovieLayer != layer) {
        if (hoveredMovieLayer) {
            [hoveredMovieLayer release];
            hoveredMovieLayer = nil;
        }
        
        hoveredMovieLayer = [layer retain];
        
        if (hoveredMovieLayer) {
            [CATransaction begin];
            [CATransaction setValue:[NSNumber numberWithDouble:0.0] forKey:kCATransactionAnimationDuration];
            
            //dontLayoutBecauseOfHighlight = YES;
            hoverHighlightLayer.hidden = NO;
            hoverHighlightLayer.anchorPoint = hoveredMovieLayer.anchorPoint;
            hoverHighlightLayer.bounds = CGRectInset(hoveredMovieLayer.bounds, -20, -20);
            hoverHighlightLayer.position = hoveredMovieLayer.position;
            hoverHighlightLayer.zPosition = hoveredMovieLayer.zPosition - 1;
            hoverHighlightLayer.transform = hoveredMovieLayer.transform;
            
            [CATransaction commit];
        } else {
            hoverHighlightLayer.hidden = YES;
        }            
    }
}

- (void) setListOfLayersInOrder:(NSArray*)_listOfLayersInOrder
{
    if (listOfLayersInOrder) {
        [listOfLayersInOrder release];
        listOfLayersInOrder = nil;
    }
    
    listOfLayersInOrder = [_listOfLayersInOrder retain];
}

- (void) setListOfArrangedObjects:(NSArray*)arrangedObjects
{
    if (arrangedListOfObjects) {
        [arrangedListOfObjects release];
        arrangedListOfObjects = nil;
    }
    arrangedListOfObjects = [arrangedObjects retain];
}

static const CGFloat WS = 75.0;
static const CGFloat W = 280.0;
static const CGFloat H = 400.0;
static const CGFloat HS = 75.0;

- (void) layoutSublayersOfLayer:(CALayer*)layer
{
    NSLog(@"laying out");
    
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
        opacity *= 0.0;
    }
    
    NSArray* frontMostLayers = [listOfLayersInOrder objectAtIndex:[listOfLayersInOrder count] - 1];
    CGSize const size = floorLayer.bounds.size;
    CGFloat width = WS + ((W + WS) * [frontMostLayers count]);
    CGFloat height = (HS + H + HS);

    // TODO: WTF is this equation, and why does it work??
    float xFactor = -(width / 2.0) + (W*2.5) - (WS* .5);
    
    CALayer* selectedLayer = nil;
    
    for (CALayer* sublayer in frontMostLayers) {
        // Translate
        CATransform3D trans = CATransform3DIdentity;
        trans = CATransform3DTranslate(trans, xFactor, HS, 0.0);
        
        [sublayer setTransform:trans];
        
        xFactor += WS + W;
        
        if (((MovieLayer*)sublayer).movie == selectedMovie) {
            selectedLayer = sublayer;
        }
    }

    CGFloat scale = size.height / height;
    CATransform3D p =  CATransform3DIdentity;
    p = CATransform3DScale(p, scale, scale, 1.0);
    
    if (selectedLayer) {
        selectedHighlightLayer.hidden = NO;
        selectedHighlightLayer.anchorPoint = selectedLayer.anchorPoint;
        selectedHighlightLayer.bounds = CGRectInset(selectedLayer.bounds, -20, -20);
        selectedHighlightLayer.position = selectedLayer.position;
        selectedHighlightLayer.zPosition = selectedLayer.zPosition - 1;
        selectedHighlightLayer.transform = selectedLayer.transform;
    } else {
        selectedHighlightLayer.hidden = YES;
    }
    
    if (scrollToSelectedMovie && selectedLayer && [selectedLayer isKindOfClass:[CALayer class]]) {
        float pointOnX = selectedLayer.frame.origin.x - W;
        p = CATransform3DTranslate(p, -pointOnX, 0.0, 0.0);
    }

    [floorLayer setSublayerTransform:p];
    [CATransaction commit];
}

@end
