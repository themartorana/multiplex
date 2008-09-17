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
        [CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY],
        [CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX],
        [CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth scale:0.95 offset:0.0],
        [CAConstraint constraintWithAttribute:kCAConstraintHeight relativeTo:@"superlayer" attribute:kCAConstraintHeight scale:0.70 offset:0.0],
        nil
    ];
    [self.layer addSublayer:floorLayer];
    
    listOfLayersInOrder = [[NSMutableArray alloc] initWithObjects:[NSMutableArray array], nil];
    layersByID = [[NSMutableDictionary alloc] init];
}

- (void) dealloc
{
    [layersByID release];
    [listOfLayersInOrder release];
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
        NSMutableArray* allLayers = [listOfLayersInOrder objectAtIndex:0];
        int oldCount = [allLayers count];
        NSArray* allObjects = [object content];
        int count = [[object content] count];
        if (oldCount != count) {
            NSMutableArray* layersInOrder = [NSMutableArray arrayWithCapacity:count];
            for (Movie* movie in allObjects) {
                NSManagedObjectID* objectID = [movie objectID];
                MovieLayer* layer = [layersByID objectForKey:objectID];
                if (!layer) {
                    layer = [self layerForMovie:movie];
                    [floorLayer addSublayer:layer];
                    [layersByID setObject:layer forKey:objectID];
                } else {
                    [allLayers removeObject:layer];
                }
                [layersInOrder addObject:layer];
            }
            for (CALayer* layerToRemove in allLayers) {
                [layerToRemove removeFromSuperlayer];
            }
            [listOfLayersInOrder replaceObjectAtIndex:0 withObject:layersInOrder];
            [floorLayer setNeedsLayout];
        }
    } else if ([@"arrangedObjects" isEqualToString:keyPath]) {
        NSArray* arrangedObjects = [object arrangedObjects];

        int count = [arrangedObjects count];
        for (int i = [listOfLayersInOrder count] - 1; i >= 0; i--) {
            if ([[listOfLayersInOrder objectAtIndex:i] count] > count) {
                break;
            }
            [listOfLayersInOrder removeLastObject];
        }
                
        /*  Determine which items already have layers, and which need to have
         *  layers created for them.
         */
        NSMutableArray* layersInOrder = [NSMutableArray arrayWithCapacity:count];
        for (Movie* movie in arrangedObjects) {
            NSManagedObjectID* objectID = [movie objectID];
            MovieLayer* layer = [layersByID objectForKey:objectID];
            if (!layer) {
                layer = [self layerForMovie:movie];
                [floorLayer addSublayer:layer];
                [layersByID setObject:layer forKey:objectID];
            }
            [layersInOrder addObject:layer];
        }
        
        /*  Keep these around for next time...
         */
        [listOfLayersInOrder addObject:layersInOrder];

        CGFloat opacity = 1.0;
        NSMutableSet* tagged = [NSMutableSet set];
        for (NSArray* layersInOrder in [listOfLayersInOrder reverseObjectEnumerator]) {
            for (CALayer* layer in layersInOrder) {
                if (![tagged containsObject:layer]) {
                    layer.opaque = (opacity == 1.0);
                    layer.opacity = opacity;
                    [tagged addObject:layer];
                }
            }
            opacity *= 0.2;
        }
        
        /*  Tell the root layer to re-layout.
         */
        [floorLayer setNeedsLayout];
    }
}

@end


#pragma mark -
@implementation MainView (LayerStuff)

CGFloat WS = 75.0;
CGFloat W = 280.0;
CGFloat H = 400.0;
CGFloat HS = 75.0;

- (MovieLayer*) layerForMovie:(Movie*)movie
{
    MovieLayer* layer = [MovieLayer layer];
    layer.delegate = self;
    layer.movie = movie;
    layer.backgroundColor = CGColorCreateGenericRGB(0.5, 0.5, 0.5, 1.0);
    layer.frame = CGRectMake(0.0, 0.0, W, H);
    layer.position = CGPointZero;
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

- (NSDictionary*) computeParametersForSize:(CGSize)size andCount:(int)count
{
    CGFloat aspectToFit = size.width / size.height;
    
    struct result {
        int rows;
        int columns;    
        /**/
        CGFloat aspect;
        CGFloat score;
    }* resultSet = alloca(count * sizeof(struct result));
    bzero(resultSet, sizeof(struct result));
    
    if (count > 0) {
        int rows = 0;
        resultSet--;
        do {
            resultSet++;
            resultSet->rows = ++rows;
            resultSet->columns = (count / resultSet->rows) + ((count % resultSet->rows) > 0);
            resultSet->aspect = (((W+WS)/(H+HS)) * resultSet->columns / 2.0) / resultSet->rows;
            resultSet->score = resultSet->aspect - aspectToFit;
        } while (resultSet->score > -0.005);
        
        CGFloat lowScore = CGFLOAT_MAX;
        for (struct result* rp = resultSet, *rb = resultSet - rows; rp > rb; rp--) {
            if (fabsf(rp->score) < lowScore) {
                resultSet = rp;
                lowScore = fabsf(rp->score);
            }
        }
    }
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithInt:resultSet->columns], @"columns",
        [NSNumber numberWithInt:resultSet->rows], @"rows",
        nil
    ];
}

- (void) layoutSublayersOfLayer:(CALayer*)layer
{
    NSAssert(layer == floorLayer, @"wtf?");
    /*  This base transform sets up the origin (0, 0) to the center of the 
     *  layer.
     */
    CATransform3D b = CATransform3DIdentity;
    b = CATransform3DTranslate(b, floorLayer.bounds.size.width / 2.0, floorLayer.bounds.size.height / 2.0, 0.0);

    CGSize const size = floorLayer.bounds.size;
    BOOL lastWasEmpty = YES;
    CGFloat columns = 0;
    CGFloat rows = 0;
    CGFloat height = 0;
    CGFloat width = 0;
    CGFloat radius = 0;
    CGFloat length = 0;
    for (NSArray* layersInOrder in listOfLayersInOrder) {
        int count = [layersInOrder count];
        lastWasEmpty = !count;
        NSDictionary* parameters = [self computeParametersForSize:floorLayer.bounds.size andCount:count];
        
        columns = [[parameters objectForKey:@"columns"] floatValue];
        rows = [[parameters objectForKey:@"rows"] floatValue];
        
        height = (HS + ((H + WS) * rows));
        length = (WS + ((W + WS) * columns));
        radius = length / M_PI;
        
        int x = 0;
        int y = rows;
        for (MovieLayer* layer in layersInOrder) {
            CGFloat chord = WS + (W / 2.0) + ((W + WS) * x);
            CGFloat theta = -chord / radius;
            
            CATransform3D t = b;
            t = CATransform3DTranslate(t, radius * -cos(theta), ((H + HS) * y) - (H / 2.0) - (height / 2.0), 0.0);
            if (columns <= 3) {
                width = length;
            } else {
                width = radius * 2.0;
                t = CATransform3DTranslate(t, 0.0, 0.0, radius * sin(theta));
                t = CATransform3DRotate(t, theta + M_PI/2.0, 0.0, 1.0, 0.0);
            }
            layer.transform = t;
            
            y -= 1;
            if (!y) {
                x++;
                y = rows;
            }
        }
    }

    CGFloat scale = size.width / width;
    if (scale * height > size.height) {
        scale = size.height / height;
    }
    
    /*  Add in our scale factor and perspective...  then throw a little 
     *  rotational "stank" on it.  ;)
     */
    if (!lastWasEmpty) {
        CATransform3D p = CATransform3DIdentity;
        p = CATransform3DScale(p, scale, scale, 1.0);
        p.m34 = 1.0 / -MAX(width, 2000);
        p = CATransform3DRotate(p, -0.05, 1.0, 0.0, 0.0);
        floorLayer.sublayerTransform = p;
    }
}

@end
