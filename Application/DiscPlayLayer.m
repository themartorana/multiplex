#import "DiscPlayLayer.h"
#import "ButtonLayer.h"
#import "Disc.h"
#import "Movie.h"
#import "Media.h"
#import "CGColorFactory.h"
#import "ApplicationResources.h"
#import <QuartzCore/QuartzCore.h>

@implementation DiscPlayLayer

@synthesize disc;
@synthesize hovered;

- (DiscPlayLayer*) init
{
    if (self = [super init]) {
        [self setUpPlayLayer];
        self.backgroundColor = [CGColorFactory blackHalfTransparent];
        self.borderColor = CGColorGetConstantColor(kCGColorWhite);
        self.cornerRadius = 10.0;
    }
    
    return self;
}

- (void) setUpPlayLayer
{
    float universalPadding = 20.0;
    
    self.anchorPoint = CGPointZero;
    self.bounds = CGRectMake(0.0, 0.0, 370.0, 109.0);
    
    playButtonLayer = [ButtonLayer buttonLayerWithUpState:[ApplicationResources playButton] downState:[ApplicationResources playButtonDown]];
    playButtonLayer.anchorPoint = CGPointZero;
    playButtonLayer.frame = CGRectMake(370.0 - 76.0 - universalPadding, 
                                       (109.0/2.0) - (76.0/2.0), 
                                       76.0,
                                       76.0);
    [self addSublayer:playButtonLayer];
 
    greyPlayButtonLayer = [ButtonLayer buttonLayerWithUpState:[ApplicationResources playButtonInactive] downState:[ApplicationResources playButton]];
    greyPlayButtonLayer.anchorPoint = CGPointZero;
    greyPlayButtonLayer.frame = CGRectMake(370.0 - 76.0 - universalPadding, 
                                       (109.0/2.0) - (76.0/2.0), 
                                       76.0,
                                       76.0);
    [self addSublayer:greyPlayButtonLayer];
    
    
    discNumberTitle = [CATextLayer layer];
    discNumberTitle.font = [NSFont boldSystemFontOfSize:28.0];
    discNumberTitle.fontSize = 28.0;
    discNumberTitle.foregroundColor = [CGColorFactory discPlayLayerUnhoveredForegroundColor];
    discNumberTitle.anchorPoint = CGPointZero;
    discNumberTitle.frame = CGRectMake(universalPadding, 
                                       109.0 - 28.0 - (universalPadding/2), 
                                       370.0 - (universalPadding * 2.0), 
                                       32.0);
    [self addSublayer:discNumberTitle];
    
    descriptionLayer = [CATextLayer layer];
    descriptionLayer = [CATextLayer layer];
    descriptionLayer.font = [NSFont boldSystemFontOfSize:13.0];
    descriptionLayer.fontSize = 13.0;
    descriptionLayer.foregroundColor = [CGColorFactory discPlayLayerUnhoveredForegroundColor];
    descriptionLayer.anchorPoint = CGPointZero;
    descriptionLayer.frame = CGRectMake(universalPadding,
                                        discNumberTitle.frame.origin.y - (universalPadding / 2) - 55.0,
                                        250.0,
                                        55.0);
    [self addSublayer:descriptionLayer];
}

- (void) setDisc:(Disc*)_disc
{
    disc = _disc;
    
    if (disc) {
        discNumberTitle.string = [NSString stringWithFormat:@"Disc %@", disc.number];
        descriptionLayer.string = [NSString stringWithFormat:@"Disc %@ of %d", disc.number, [disc.movie.allDiscs count]];
        
        BOOL shouldHide = YES;
        
        if ([disc.allMedia count] > 0) {
            NSArray* allMedia = [disc.allMedia allObjects];
            for (Media* media in allMedia) {
                if ([media.isAvailable boolValue]) {
                    shouldHide = NO;
                }
            }
        }
        
        playButtonLayer.hidden = shouldHide;
    }
    
}

- (void) setHovered:(BOOL)isHovered
{
    hovered = isHovered;
    
    if (isHovered) {
        self.backgroundColor = [CGColorFactory black];
        self.borderWidth = 2.0;
        
        discNumberTitle.foregroundColor = CGColorCreateGenericRGB(231.0/255.0, 111.0/255.0, 52.0/255.0, 1.0);
        descriptionLayer.foregroundColor = CGColorGetConstantColor(kCGColorWhite);
        greyPlayButtonLayer.hidden = YES;
    }
    else {
        self.backgroundColor = [CGColorFactory blackOneQuarterTransparent];
        self.borderWidth = 0.0;

        discNumberTitle.foregroundColor = [CGColorFactory discPlayLayerUnhoveredForegroundColor];
        descriptionLayer.foregroundColor = [CGColorFactory discPlayLayerUnhoveredForegroundColor];
        greyPlayButtonLayer.hidden = NO;
    }
}

@end
