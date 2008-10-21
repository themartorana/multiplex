#import <QuartzCore/QuartzCore.h>

@class Movie;
@class MovieLayer;

@protocol MultiplexLayoutManager

- (id<MultiplexLayoutManager>) initWithFloorLayer:(CALayer*)layer;

- (void) setHoveredMovieLayer:(MovieLayer*)layer;
- (void) setListOfLayersInOrder:(NSArray*)listOfLayersInOrder;
- (void) setListOfArrangedObjects:(NSArray*)arrangedObjects;

- (void) layoutSublayersOfFloorLayer;

@end
