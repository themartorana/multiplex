#import "WorkingStatusView.h"
#import <Toolkit/Toolkit.h>
#import "Activity.h"

@interface WorkingStatusView(Private)

- (void) _startSpinner;
- (void) _stopSpinner;

@end


@implementation WorkingStatusView

#pragma mark Public Implementation

- (void) awakeFromNib
{
    [self setWantsLayer:YES];
    [self setHidden:YES];
    
    [self layer].layoutManager = [CAConstraintLayoutManager layoutManager];
    
    activityDictionary = [[NSMutableDictionary dictionary] retain];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityStarted:) name:ActivityStartedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityTerminated:) name:ActivityTerminatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityPercentCompleteUpdated:) name:ActivityPercentCompleteUpdatedNotification object:nil];
}

- (void) dealloc
{
    [activityDictionary release];
    [super dealloc];
}

- (void) activityStarted:(NSNotification*)notification
{
    NSString* activityString = ((Activity*)[notification object]).name;
 
    // Look in the dictionary for this activity
    NSMutableArray* activityArray = nil;
    if (activityArray = [activityDictionary objectForKey:activityString]) {
        [activityArray addObject:[notification object]];
    }
    else {
        // There is a new activity!
        activityArray = [NSMutableArray arrayWithObject:[notification object]];
        [activityDictionary setObject:activityArray forKey:activityString];
    }
    
    // Start the spinner
    [self setHidden:NO];
    [self _startSpinner];
}

- (void) activityTerminated:(NSNotification*)notification
{
    NSString* activityString = ((Activity*)[notification object]).name;

    // Look in the dictionary for this activity
    NSMutableArray* activityArray = nil;
    if (activityArray = [activityDictionary objectForKey:activityString]) {
        [activityArray removeObject:[notification object]];
        if (![activityArray count]) {
            [activityDictionary removeObjectForKey:activityString];
        }
    }
    
    if (![activityDictionary count]) {
        [self _stopSpinner];
        [self setHidden:YES];
    }
}

- (void) activityPercentCompleteUpdated:(NSNotification*)notification
{
    [[self layer] setNeedsDisplay];
}

#pragma mark Private Methods

- (void) _startSpinner
{
    if (!_spinnerLayer) {
        _spinnerLayer = [[IndeterminateProgressIndicatorLayer layer] retain];
        _spinnerLayer.constraints = [NSArray arrayWithObjects:
                                     [CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMinX],
                                     [CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"superlayer" attribute:kCAConstraintMinY],
                                     [CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth scale:0.0 offset:20.0],
                                     [CAConstraint constraintWithAttribute:kCAConstraintHeight relativeTo:@"superlayer" attribute:kCAConstraintHeight scale:0.0 offset:20.0],
                                     nil];
        [[self layer] addSublayer:_spinnerLayer];

    }
}

- (void) _stopSpinner
{
    if (_spinnerLayer) {
        [_spinnerLayer removeFromSuperlayer];
        [_spinnerLayer release];
        _spinnerLayer = nil;
    }
}

@end
