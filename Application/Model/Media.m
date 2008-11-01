#import "Media.h"
#import "Disc.h"

@implementation Media

@dynamic disc;
@dynamic tag;
@dynamic type;
@dynamic pathToFile;
@dynamic engine;
@dynamic isAvailable;
@dynamic isLocal;

- (void) setDisc:(Disc*)_disc
{
    [super willChangeValueForKey:@"disc"];
    
    if (disc) {
        if (isAvailable) {
            disc.availableMediaCount = [NSNumber numberWithInt:[disc.availableMediaCount intValue] - 1];
        }
        
        [disc release];
        disc = nil;
    }
    
    disc = [_disc retain];
    
    if (disc && isAvailable) {
        disc.availableMediaCount = [NSNumber numberWithInt:[disc.availableMediaCount intValue] + 1];
    }
    
    [super didChangeValueForKey:@"disc"];
}


- (void) setIsAvailable:(NSNumber*)_isAvailable
{
    [super willChangeValueForKey:@"isAvailable"];
    
    BOOL oldValue = FALSE;
    BOOL newValue = FALSE;
    
    if (isAvailable) {
        oldValue = [isAvailable boolValue];
        
        [isAvailable release];
        isAvailable = nil;
    }
    if (_isAvailable) {
        newValue = [_isAvailable boolValue];
    }
    
    isAvailable = [_isAvailable retain];
    
    if (disc && (oldValue != newValue)) {
        if (newValue) {
            disc.availableMediaCount = [NSNumber numberWithInt:[disc.availableMediaCount intValue] + 1];
        }
        else {
            disc.availableMediaCount = [NSNumber numberWithInt:[disc.availableMediaCount intValue] - 1];
        }
    }

    [super didChangeValueForKey:@"isAvailable"];
}

@end
