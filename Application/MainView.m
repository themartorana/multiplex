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
    }
}

@end


#pragma mark -
@implementation MainView (LayerStuff)

CGFloat WS = 75.0;
CGFloat W = 280.0;
CGFloat H = 400.0;
CGFloat HS = 45.0;

- (MovieLayer*) layerForMovie:(Movie*)movie
{
    MovieLayer* layer = [MovieLayer layer];
    layer.delegate = self;
    layer.movie = movie;
    layer.borderWidth = 3.0;
    layer.borderColor = CGColorCreateGenericRGB(1.0, 1.0, 1.0, 1.0);
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
        CGFloat length;
        CGFloat radius;
        CGFloat width;
        CGFloat height;
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
            resultSet->height = HS + ((H + WS) * resultSet->rows);
            resultSet->length = WS + ((W + WS) * resultSet->columns);
            resultSet->radius = resultSet->length / M_PI;
            resultSet->width = resultSet->radius * 2.0;
            resultSet->aspect = resultSet->width / resultSet->height;
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
    
    CGFloat scale;
    if (resultSet->aspect < 0.0) {
        scale = size.height / resultSet->height;
    } else {
        scale = size.width / resultSet->width;
    }
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithInt:resultSet->columns], @"columns",
        [NSNumber numberWithFloat:resultSet->height], @"height",
        [NSNumber numberWithInt:resultSet->rows], @"rows",
        [NSNumber numberWithFloat:resultSet->radius], @"radius",
        [NSNumber numberWithFloat:scale], @"scale",
        [NSNumber numberWithFloat:resultSet->width], @"width",
        nil
    ];
}

- (void) layoutSublayersOfLayer:(CALayer*)layer
{
    NSDictionary* parameters = [self computeParametersForSize:floorLayer.bounds.size andCount:totalCount];
    
    CGFloat rows = [[parameters objectForKey:@"rows"] floatValue];
    CGFloat radius = [[parameters objectForKey:@"radius"] floatValue];
    CGFloat scale = [[parameters objectForKey:@"scale"] floatValue];
    CGFloat width = [[parameters objectForKey:@"width"] floatValue];
    CGFloat height = [[parameters objectForKey:@"height"] floatValue];

    /*  This base transform sets up the origin (0, 0) to the center of the 
     *  layer.
     */
    CATransform3D b = CATransform3DIdentity;
    b = CATransform3DTranslate(b, floorLayer.bounds.size.width / 2.0, 0.0, 0.0);

    /*  Loop through the layers in the list 
     */
    int x = 0;
    int y = rows;
    for (MovieLayer* layer in layersInOrder) {
        CGFloat chord = WS + (W / 2.0) + ((W + WS) * x);
        CGFloat theta = -chord / radius;
        
        CATransform3D t = b;
        t = CATransform3DTranslate(t, radius * -cos(theta), (H / 2.0) + ((H + HS) * y) - (height / 2.0), radius * sin(theta));
        t = CATransform3DRotate(t, theta - M_PI/2.0, 0.0, 1.0, 0.0);
        layer.transform = t;

        y -= 1;
        if (!y) {
            x++;
            y = rows;
        }
    }
    
    /*  Add in our scale factor and perspective...  then throw a little 
     *  rotational "stank" on it.  ;)
     */
    CATransform3D p = CATransform3DIdentity;
	p = CATransform3DScale(p, scale, scale, 1.0);
    p.m34 = 1.0 / -width;
	p = CATransform3DRotate(p, -0.05, 1.0, 0.0, 0.0);
    floorLayer.sublayerTransform = p;
}

@end
