#import <QuartzCore/QuartzCore.h>

@class Movie;
@class MovieLayer;

@protocol MultiplexLayoutManager <NSObject>

- (id<MultiplexLayoutManager>) initWithManagingLayer:(CALayer*)layer;
- (void) clearManagingLayerOfExtras;

- (void) setHoveredMovieLayer:(MovieLayer*)layer;
- (void) setListOfLayersInOrder:(NSArray*)listOfLayersInOrder;
- (void) setListOfArrangedObjects:(NSArray*)arrangedObjects;

@end
