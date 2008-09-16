#import "MainView.h"
#import "Movie.h"
#import "MovieLayer.h"
#import <QuartzCore/QuartzCore.h>

@interface MainView (LayerStuff)
- (MovieLayer*) layerForMovie:(Movie*)movie;
- (void) drawLayer:(MovieLayer*)layer inContext:(CGContextRef)c;
- (void) layoutSublayersOfLayer:(CALayer*)layer;
@end

@interface MainView (Private)
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context;
@end

@implementation MainView
@synthesize content;

- (void) awakeFromNib
{
    self.layer = [CALayer layer];
    [self setWantsLayer:YES];
    self.layer.backgroundColor = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 1.0);
    self.layer.layoutManager = [CAConstraintLayoutManager layoutManager];
    
    floorLayer = [CALayer layer];
    floorLayer.delegate = self;
    floorLayer.layoutManager = self;
    floorLayer.borderWidth = 2.0;
    floorLayer.borderColor = CGColorCreateGenericRGB(1.0, 0.0, 0.0, 1.0);
    floorLayer.constraints = [NSArray arrayWithObjects:
        [CAConstraint constraintWithAttribute:kCAConstraintMidY relativeTo:@"superlayer" attribute:kCAConstraintMidY],
        [CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX],
        nil
    ];
    [self.layer addSublayer:floorLayer];
}

- (void) dealloc
{
    [layersByID release];
    [layersInOrder release];
    [super dealloc];
}

- (void) setContent:(id)_content
{
    if (content != _content) {
        [content release];
        content = [_content retain];
        
        if ([content isKindOfClass:[NSArrayController class]]) {
            [content addObserver:self forKeyPath:@"content.@count" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
            [content addObserver:self forKeyPath:@"arrangedObjects" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
        } else {
            [NSException raise:NSInvalidArgumentException format:@"content must be of type NSArrayController."];
        }
    }
}

@end


#pragma mark -
@implementation MainView (Private)

- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    if ([@"content.@count" isEqualToString:keyPath]) {
        totalCount = [[object content] count];
        [floorLayer setNeedsLayout];
    } else if ([@"arrangedObjects" isEqualToString:keyPath]) {
        NSArray* arrangedObjects = [object arrangedObjects];
        
        /*  Determine which items already have layers, and which need to have
         *  layers created for them.
         */
        NSMutableArray* newLayersInOrder = [NSMutableArray arrayWithCapacity:[arrangedObjects count]];
        if (!layersByID) {
            layersByID = [[NSMutableDictionary alloc] init];
        }
        for (Movie* movie in arrangedObjects) {
            NSManagedObjectID* objectID = [movie objectID];
            MovieLayer* layer = [layersByID objectForKey:objectID];
            if (!layer) {
                layer = [self layerForMovie:movie];
                [floorLayer addSublayer:layer];
                [layersByID setObject:layer forKey:objectID];
            }
            [newLayersInOrder addObject:layer];
        }
        
        /*  Keep these around for next time...
         */
        [layersInOrder release];
        layersInOrder = [newLayersInOrder retain];
        
        /*  Tell the root layer to re-layout.
         */
        [floorLayer setNeedsLayout];
    }
}

@end


#pragma mark -
@implementation MainView (LayerStuff)

- (MovieLayer*) layerForMovie:(Movie*)movie
{
    MovieLayer* layer = [MovieLayer layer];
    layer.delegate = self;
    layer.movie = movie;
    layer.backgroundColor = CGColorCreateGenericRGB(1.0, 1.0, 1.0, 0.5);
    return layer;
}

- (void) drawLayer:(MovieLayer*)layer inContext:(CGContextRef)c
{
    /*  Movie layers drawn here  */
}

- (id<CAAction>) actionForLayer:(CALayer*)layer forKey:(NSString*)key
{
    if ([key isEqualToString:@"position"]) {
        return [CAAnimation animation];
    }
    return nil;
}

CGFloat WS = 2.0;
CGFloat W = 14.0;
CGFloat H = 20.0;
CGFloat S = 1.0;

- (void) layoutSublayersOfLayer:(CALayer*)layer
{
    CGFloat i = 1.0;
    CGFloat length = ((W + WS) * [layersInOrder count]) + (WS / 2.0);
    CGFloat radius = length / M_PI;
    CGFloat maxRadius = (((W + WS) * totalCount) + (WS / 2.0)) / M_PI;
    for (MovieLayer* layer in layersInOrder) {
        layer.frame = CGRectMake(0.0, 0.0, W, H);
        layer.position = CGPointZero;
        CGFloat theta = (((W + WS) * i) - ((W + WS) / 2.0)) / radius;
        
        CATransform3D t = CATransform3DIdentity;
        t = CATransform3DTranslate(t, maxRadius * S, 0.0, 0.0);
        t = CATransform3DTranslate(t, radius * cos(theta), 0.0, radius * -sin(theta));
        t = CATransform3DRotate(t, theta - M_PI/2.0, 0.0, 1.0, 0.0);
        layer.transform = t;

        i += 1.0;
    }

    CATransform3D p = CATransform3DIdentity;
//    p = CATransform3DTranslate(p, 0.0, 0.0, -500.0);
	p = CATransform3DScale(p, S, S, 1.0);
    p.m34 = 1.0 / -2000;
    p = CATransform3DRotate(p, 0.1, 1.0, 0.0, 0.0);
    floorLayer.sublayerTransform = p;
}

- (CGSize) preferredSizeOfLayer:(CALayer*)layer
{
    CGFloat length = ((W + WS) * totalCount) + (WS / 2.0);
    CGFloat radius = length / M_PI;
    return CGSizeMake(radius * 2 * S, H * S);
}

@end
