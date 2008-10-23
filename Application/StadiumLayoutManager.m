//
//  StadiumLayoutManager.m
//  Multiplex
//
//  Created by David Martorana on 10/21/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "StadiumLayoutManager.h"
#import "MultiplexColorFactory.h"
#import "Movie.h"
#import "MovieLayer.h"

#import <QuartzCore/QuartzCore.h>
#import <Toolkit/CALayer+IndyHallLabs.h>

@implementation StadiumLayoutManager

- (id<MultiplexLayoutManager>) initWithManagingLayer:(CALayer*)_floorLayer
{
    if (self == [super init]) {
        radialGradientLayer = [CALayer layer];
        radialGradientLayer.hidden = YES;
        radialGradientLayer.delegate = self;
        radialGradientLayer.position = CGPointZero;
        radialGradientLayer.frame = CGRectMake(0, 0, 100, 100);
        [radialGradientLayer setNeedsDisplay];
        [_floorLayer addSublayer:radialGradientLayer];
        
        hoverHighlightLayer = [[CALayer layer] retain];
        hoverHighlightLayer.borderColor = [MultiplexColorFactory multiplexOrange];
        hoverHighlightLayer.borderWidth = 10.0;
        hoverHighlightLayer.cornerRadius = 10.0;
        hoverHighlightLayer.hidden = YES;
        [_floorLayer addSublayer:hoverHighlightLayer];
        
        // To hold the title and its reflection
        titleContainerLayer = [CALayer layer];
        titleContainerLayer.anchorPoint = CGPointZero;
        titleContainerLayer.frame = CGRectMake(0.0, 100.0, _floorLayer.superlayer.frame.size.width, 100.0);
        titleContainerLayer.layoutManager = [CAConstraintLayoutManager layoutManager];
        //titleContainerLayer.borderColor = [MultiplexColorFactory multiplexOrange];
        //titleContainerLayer.borderWidth = 2.0;
        titleContainerLayer.autoresizingMask = kCALayerWidthSizable;
        [_floorLayer addSublayer:titleContainerLayer];
        
        titleLayer = [CATextLayer layer];
        titleLayer.anchorPoint = CGPointZero;
        titleLayer.wrapped = NO;
        titleLayer.alignmentMode = kCAAlignmentCenter;
        titleLayer.font = [NSFont systemFontOfSize:40.0];
        titleLayer.fontSize = 40.0;
        titleLayer.name = @"titleLayer";
        titleLayer.constraints = [NSArray arrayWithObjects:
                                  [CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX],
                                  [CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY scale:1.0 offset:-9.0],
                                  [CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth scale:0.0 offset:900.0],
                                  nil];
        titleLayer.name = @"titleLayer";
        titleLayer.truncationMode = kCATruncationEnd;
        [titleContainerLayer addSublayer:titleLayer];
        
        titleReflectionLayer = [[CATextLayer layer] retain];
        titleReflectionLayer.anchorPoint = CGPointZero;
        titleReflectionLayer.wrapped = NO;
        titleReflectionLayer.alignmentMode = kCAAlignmentCenter;
        titleReflectionLayer.font = [NSFont systemFontOfSize:40.0];
        titleReflectionLayer.fontSize = 40.0;
        titleReflectionLayer.foregroundColor = [MultiplexColorFactory white];
        titleReflectionLayer.name = @"titleReflectionLayer";
        titleReflectionLayer.transform = CATransform3DMakeScale(1.0, -1.0, 1.0);
        titleReflectionLayer.constraints = [NSArray arrayWithObjects:
                                            [CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX],
                                            [CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"titleLayer" attribute:kCAConstraintMinY scale:1.0 offset:14.0],
                                            [CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth scale:0.0 offset:900.0],
                                            nil];
        titleReflectionLayer.name = @"titleReflectionLayer";
        titleReflectionLayer.truncationMode = kCATruncationEnd;
        
        [titleReflectionLayer setMask:[CALayer maskLayer]];
        [titleContainerLayer addSublayer:titleReflectionLayer];
        
        [titleReflectionLayer bind:@"string" toObject:titleLayer withKeyPath:@"string" options:nil];    
    }
    
    return self;
}

- (void) clearManagingLayerOfExtras
{
    
}

- (void) setListOfLayersInOrder:(NSArray*)_listOfLayersInOrder
{
    if (listOfLayersInOrder) {
        [listOfLayersInOrder release];
        listOfLayersInOrder = nil;
    }
    
    listOfLayersInOrder = [_listOfLayersInOrder retain];
}

- (void) setListOfArrangedObjects:(NSArray*)_arrangedListOfObjects
{
    if (arrangedListOfObjects) {
        [arrangedListOfObjects release];
        arrangedListOfObjects = nil;
    }
    
    arrangedListOfObjects = [_arrangedListOfObjects retain];
    
    radialGradientLayer.hidden = (!arrangedListOfObjects || [arrangedListOfObjects count] == 0);
}

- (void) setHoveredMovieLayer:(MovieLayer*)movieLayer;
{
    [CATransaction begin];
    [CATransaction setValue:[NSNumber numberWithDouble:0.0] forKey:kCATransactionAnimationDuration];
    
    Movie* movie = nil;
    if (movieLayer) {
        movie = movieLayer.movie;
    }
    
    if (movie){
        titleLayer.string = movie.title;
    } else {
        titleLayer.string = @" ";
    }
    
    if (movieLayer != hoveredMovieLayer) {
        [hoveredMovieLayer release];
        hoveredMovieLayer = [movieLayer retain];
        
        if (movieLayer) {
            
            hoverHighlightLayer.hidden = NO;
            hoverHighlightLayer.anchorPoint = movieLayer.anchorPoint;
            hoverHighlightLayer.bounds = CGRectInset(movieLayer.bounds, -20, -20);
            hoverHighlightLayer.position = movieLayer.position;
            hoverHighlightLayer.zPosition = movieLayer.zPosition - 1;
            hoverHighlightLayer.transform = movieLayer.transform;
            
        } else {
            hoverHighlightLayer.hidden = YES;
        }
        
    }
    [CATransaction commit];
}


static const CGFloat WS = 75.0;
static const CGFloat W = 280.0;
static const CGFloat H = 400.0;
static const CGFloat HS = 75.0;

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

- (void)layoutSublayersOfLayer:(CALayer *)floorLayer
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
        opacity *= 0.2;
    }
    
    /*  This base transform sets up the origin (0, 0) to the center of the 
     *  layer along the X and Y axes.
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
    
    /*  Process the rows, back-to-front.
     */
    CGFloat base = 0;
    for (NSArray* layersInOrder in listOfLayersInOrder) {
        int count = [layersInOrder count];
        lastWasEmpty = !count;
        NSDictionary* parameters = [self computeParametersForSize:floorLayer.bounds.size andCount:count];
        
        columns = [[parameters objectForKey:@"columns"] floatValue];
        rows = [[parameters objectForKey:@"rows"] floatValue];
        height = (HS + ((H + WS) * rows));
        length = (WS + ((W + WS) * columns));
        radius = length / M_PI;
        if (0 == base) {
            base = height;
        }
        
        int x = 0;
        int y = rows;
        for (MovieLayer* layer in layersInOrder) {
            CGFloat chord = WS + (W / 2.0) + ((W + WS) * x);
            
            /*  Starting with the base transform, translate the layer along the
             *  Y axis.
             */
            CATransform3D t = b;
            t = CATransform3DTranslate(t, 0.0, ((H + HS) * y) - (H / 2.0), 0.0);
            
            /*  If there are fewer than five columns, we'll just grid this 
             *  thing.  Otherwise, we'll need to translate on the X and Z and 
             *  do a little rotating to make things look right.  For the 
             *  rotation, we need to go one direction on the left-hand of the 
             *  arc, and the opposite direction on the right-hand.
             */
            if (columns < 4) {
                width = length;
                t = CATransform3DTranslate(t, chord - (length / 2.0), 0.0, -columns);
            } else {
                width = radius * 2.0;
                CGFloat theta = -chord / radius;
                t = CATransform3DTranslate(t, radius * -cos(theta), 0.0, radius * sin(theta));
                
                if (y > (columns / 2)) {
                    t = CATransform3DRotate(t, theta - M_PI/2.0, 0.0, 1.0, 0.0);
                } else {
                    t = CATransform3DRotate(t, theta + M_PI/2.0, 0.0, 1.0, 0.0);
                }
            }
            layer.transform = t;
            
            /*  Setup for the next iteration.
             */
            y -= 1;
            if (!y) {
                x++;
                y = rows;
            }
        }
    }
    
    if (!lastWasEmpty) {
        /*  Determine the scale that will "best" fit the screen.
         */
        CGFloat scale = size.width / width;
        if (scale * height > size.height) {
            scale = size.height / height;
        }
        
        radialGradientLayer.position = CGPointZero;
        radialGradientLayer.bounds = CGRectMake(length / 2.0, length / 2.0, width, width);
        radialGradientLayer.transform = CATransform3DRotate(b, -M_PI / 2.0, 1.0, 0.0, 0.0);
        
        /*  Add in our scale and perspective...  then throw a little rotational 
         *  "stank" on it.  ;)
         */
        CATransform3D p = CATransform3DIdentity;
        p = CATransform3DScale(p, scale, scale, 1.0);
        p = CATransform3DTranslate(p, 0.0, -height / 2.0, 0.0);
        p.m34 = 1.0 / -MAX(width, 2000);
        p = CATransform3DRotate(p, 0.075, 1.0, 0.0, 0.0);
        floorLayer.sublayerTransform = p;
    }
    
    [self setHoveredMovieLayer:nil];
    
    [CATransaction commit];
}

- (void) drawLayer:(CALayer*)layer inContext:(CGContextRef)c
{
    if (layer == radialGradientLayer) {
        [NSGraphicsContext saveGraphicsState];
        [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:c flipped:YES]];
        {
            CGRect bounds = layer.bounds;
            NSPoint center = NSMakePoint(bounds.origin.x + bounds.size.width / 2.0, bounds.origin.y + bounds.size.height / 2.0);
            
            NSColor* lightGrey = [NSColor colorWithDeviceRed:154.0/255.0 green:154.0/255.0 blue:154.0/255.0 alpha:1.0];
            NSColor* darkGrey = [NSColor colorWithDeviceRed:154.0/255.0 green:154.0/255.0 blue:154.0/255.0 alpha:0.0];
            NSGradient* gradient = [[NSGradient alloc] initWithColorsAndLocations:lightGrey, (CGFloat)0.0, darkGrey, (CGFloat)1.0, nil];
            [gradient drawFromCenter:center radius:0 toCenter:center radius:MIN(bounds.size.width, bounds.size.height)/2.0 options:0];
            [gradient release];
        }
        [NSGraphicsContext restoreGraphicsState];
    }
}

@end
