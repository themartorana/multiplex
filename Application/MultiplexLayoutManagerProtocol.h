#import <QuartzCore/QuartzCore.h>

@class Movie;
@class MovieLayer;

@protocol MultiplexLayoutManagerProtocol <NSObject>

- (id<MultiplexLayoutManagerProtocol>) initWithManagingLayer:(CALayer*)layer;
- (void) clearManagingLayerOfExtras;

- (void) setHoveredMovieLayer:(MovieLayer*)layer;
- (void) setSelectedMovieLayer:(MovieLayer*)movieLayer;

- (void) setListOfLayersInOrder:(NSArray*)listOfLayersInOrder;

// Make this concrete
- (void) layoutSublayersOfLayer:(CALayer*)layer;

- (void) setShouldShowSelectedMovieHighlight:(BOOL)show;
- (void) setShouldShowHoveredMovieHighlight:(BOOL)show;

@end
