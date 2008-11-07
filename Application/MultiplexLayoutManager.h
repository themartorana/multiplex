#import <QuartzCore/QuartzCore.h>

@class Movie;
@class MovieLayer;

@protocol MultiplexLayoutManager <NSObject>

- (id<MultiplexLayoutManager>) initWithManagingLayer:(CALayer*)layer;
- (void) clearManagingLayerOfExtras;

- (void) setHoveredMovieLayer:(MovieLayer*)layer;
- (void) setSelectedMovieLayer:(MovieLayer*)movieLayer;

- (void) setListOfLayersInOrder:(NSArray*)listOfLayersInOrder;

// Make this concrete
- (void) layoutSublayersOfLayer:(CALayer*)layer;

@end
