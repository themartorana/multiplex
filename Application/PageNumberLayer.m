#import "PageNumberLayer.h"
#import "MultiplexColorFactory.h"

@implementation PageNumberLayer

@synthesize pageNumber;

- (PageNumberLayer*) init
{
    if (self = [super init]) {
        self.layoutManager = [CAConstraintLayoutManager layoutManager];
        pageNumberTextLayer = [[CATextLayer layer] retain];
        pageNumberTextLayer.font = [NSFont boldSystemFontOfSize:16.0];
        pageNumberTextLayer.fontSize = 16.0;
        pageNumberTextLayer.foregroundColor = [MultiplexColorFactory white];
        pageNumberTextLayer.constraints = [NSArray arrayWithObjects:
                                           [CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX],
                                           [CAConstraint constraintWithAttribute:kCAConstraintMidY relativeTo:@"superlayer" attribute:kCAConstraintMidY],
                                           nil];
        [self addSublayer:pageNumberTextLayer];
    }
    
    return self;
}

- (void) dealloc
{
    [pageNumberTextLayer release];
    [super dealloc];
}

- (void) setPageNumber:(int)num
{
    pageNumber = num;
    NSString* number = [[NSNumber numberWithInt:pageNumber] stringValue];
    pageNumberTextLayer.string = number;
}

@end
