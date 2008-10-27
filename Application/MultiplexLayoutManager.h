#import <QuartzCore/QuartzCore.h>

@class Movie;
@class MovieLayer;

@protocol MultiplexLayoutManager <NSObject>

- (id<MultiplexLayoutManager>) initWithManagingLayer:(CALayer*)layer;
- (void) clearManagingLayerOfExtras;

- (void) setHoveredMovieLayer:(MovieLayer*)layer;
- (void) setSelectedMovie:(Movie*)movie;

- (void) setListOfLayersInOrder:(NSArray*)listOfLayersInOrder;

- (BOOL) changesSelectionOnSingleClick;

// Make this concrete
- (void) layoutSublayersOfLayer:(CALayer*)layer;

@end
