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
//    self.layer = [CALayer layer];
    [self setWantsLayer:YES];
    self.layer.backgroundColor = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 1.0);
    self.layer.layoutManager = [CAConstraintLayoutManager layoutManager];
    
    floorLayer = [CALayer layer];
    floorLayer.borderWidth = 1.0;
    floorLayer.borderColor = CGColorCreateGenericRGB(1.0, 0.0, 0.0, 1.0);
    floorLayer.delegate = self;
    floorLayer.layoutManager = self;
    floorLayer.position = CGPointZero;
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
        int newTotalCount = [[object content] count];
        if (totalCount < newTotalCount) {
            totalCount = newTotalCount;
            [floorLayer setNeedsLayout];
            [self.layer setNeedsLayout];
        }
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
        [self.layer setNeedsLayout];
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
    layer.borderWidth = 3.0;
    layer.borderColor = CGColorCreateGenericRGB(1.0, 1.0, 1.0, 1.0);
    layer.backgroundColor = CGColorCreateGenericRGB(0.5, 0.5, 0.5, 1.0);
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

CGFloat WS = 75.0;
CGFloat W = 280.0;
CGFloat H = 400.0;
CGFloat HS = 45.0;

- (NSDictionary*) computeParametersForSize:(CGSize)size andCount:(int)count
{
    CGFloat aspectToFit = size.width / size.height;
    
    int rows = 0;
    int columns = 0;
    CGFloat aspect = 0;
    CGFloat length = 0;
    CGFloat radius = 0;
    CGFloat width = 0;
    CGFloat height = 0;
    
    if (count > 0) {
        do {
            rows++;
            columns = (count / rows) + ((count % rows) > 0); 
            length = ((W + WS) * columns) + (WS / 2.0);
            radius = length / M_PI;
            width = radius * 2.0;
            height += H + WS;
            aspect = width / height;
        } while ((aspect - aspectToFit) > 0.01);
    }
    
    CGFloat scale = 0;
    if (aspect > 0.0) {
        scale = size.height / height;
    } else {
        scale = size.width / width;
    }
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithInt:columns], @"columns",
        [NSNumber numberWithFloat:height], @"height",
        [NSNumber numberWithInt:rows], @"rows",
        [NSNumber numberWithFloat:radius], @"radius",
        [NSNumber numberWithFloat:scale], @"scale",
        [NSNumber numberWithFloat:width], @"width",
        nil
    ];
}

- (void) layoutSublayersOfLayer:(CALayer*)layer
{
    NSDictionary* parameters = [self computeParametersForSize:NSSizeToCGSize(self.bounds.size) andCount:[layersInOrder count]];
    
    CGFloat x = 1.0;
    CGFloat y = 1.0;
    CGFloat rows = [[parameters objectForKey:@"rows"] floatValue];
    CGFloat radius = [[parameters objectForKey:@"radius"] floatValue];
    CGFloat scale = [[parameters objectForKey:@"scale"] floatValue];
    
    CATransform3D b = CATransform3DIdentity;
    b = CATransform3DTranslate(b, layer.bounds.size.width / 2.0, -layer.bounds.size.height / 2.1 / scale, 0.0);
    
    for (MovieLayer* layer in layersInOrder) {
        layer.frame = CGRectMake(0.0, 0.0, W, H);
        layer.position = CGPointZero;
        CGFloat theta = (((W + WS) * x) - ((W + WS) / 2.0)) / radius;
        
        CATransform3D t = b;
        t = CATransform3DTranslate(t, radius * cos(theta), (H + HS) * y, radius * -sin(theta));
        t = CATransform3DRotate(t, theta - M_PI/2.0, 0.0, 1.0, 0.0);
        layer.transform = t;

        y += 1.0;
        if (y > rows) {
            x++;
            y = 1.0;
        }
    }

    CATransform3D p = CATransform3DIdentity;
	p = CATransform3DScale(p, scale, scale, 1.0);
    p.m34 = 1.0 / -radius;
//    p = CATransform3DRotate(p, -0.1, 1.0, 0.0, 0.0);
    floorLayer.sublayerTransform = p;
}

- (CGSize) preferredSizeOfLayer:(CALayer*)layer
{
    NSDictionary* parameters = [self computeParametersForSize:NSSizeToCGSize(self.bounds.size) andCount:totalCount];
    NSLog(@"%@", parameters);
    CGFloat width = [[parameters objectForKey:@"width"] floatValue];
    CGFloat height = [[parameters objectForKey:@"height"] floatValue];
    CGFloat scale = [[parameters objectForKey:@"scale"] floatValue];
    return CGSizeMake(width * scale, height * scale);
}

@end
