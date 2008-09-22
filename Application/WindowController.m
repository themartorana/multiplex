#import "WindowController.h"
#import "MainView.h"
#import <QuartzCore/QuartzCore.h>
#import "Movie.h"

@implementation WindowController

- (void) awakeFromNib
{
    NSView* contentView = self.window.contentView;
    contentView.wantsLayer = YES;
    CALayer* background = contentView.layer;
    background.backgroundColor = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 1.0);
    
    [mainView setContent:movies];
    [self.window setAcceptsMouseMovedEvents:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mouseHoveredOverMovie:)
                                                 name:@"MovieNotificationTypeMovieHovered"
                                               object:mainView];
    
    [secondaryView setWantsLayer:YES];
    
    CATextLayer* secondaryViewTitleLayer = [[CATextLayer layer] retain];
    secondaryViewTitleLayer.anchorPoint = CGPointZero;
    secondaryViewTitleLayer.foregroundColor = CGColorCreateGenericRGB(1.0, 1.0, 1.0, 1.0); 
    //secondaryViewTitleLayer.backgroundColor = CGColorCreateGenericRGB(1.0, 0.0, 0.0, 0.4);
    secondaryViewTitleLayer.frame = CGRectMake(0.0, 0.0, 
                                                [secondaryView layer].bounds.size.width, 
                                                [secondaryView layer].bounds.size.height / 2);
    secondaryViewTitleLayer.wrapped = YES;
    secondaryViewTitleLayer.alignmentMode = kCAAlignmentCenter;
    secondaryViewTitleLayer.fontSize = 20.0;
    secondaryViewTitleLayer.constraints = [NSArray arrayWithObjects:
                                           [CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX],
                                           [CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth],
                                           nil];
    [[secondaryView layer] addSublayer:secondaryViewTitleLayer];
}


- (void) mouseHoveredOverMovie:(NSNotification*)notification
{
    Movie* m = [[notification userInfo] objectForKey:@"movie"];
    NSLog(@"Hovered:\t%@", m.title);
    
    for (CALayer* sublayer in [[secondaryView layer] sublayers]) {
        if ([sublayer isKindOfClass:[CATextLayer class]]) {
            ((CATextLayer*)sublayer).string = m.title;
        }
    }
}

@end
