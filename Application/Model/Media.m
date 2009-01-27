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
    Disc* disc = [self primitiveValueForKey:@"disc"];
    if (disc != _disc) {
        [super willChangeValueForKey:@"disc"];
        BOOL isAvailable = [[self primitiveValueForKey:@"isAvailable"] boolValue];
        BOOL isLocal = [[self primitiveValueForKey:@"isLocal"] boolValue];
        [self setPrimitiveValue:_disc forKey:@"disc"];
        if (isAvailable) {
            if (disc) {
                disc.availableMediaCount = [NSNumber numberWithInt:[disc.availableMediaCount intValue] - 1];
            }
            if (_disc) {
                _disc.availableMediaCount = [NSNumber numberWithInt:[_disc.availableMediaCount intValue] + 1];
            }
        }
        if (isLocal) {
            if (disc) {
                disc.localMediaCount = [NSNumber numberWithInt:[disc.localMediaCount intValue] - 1];
            }
            if (_disc) {
                _disc.localMediaCount = [NSNumber numberWithInt:[_disc.localMediaCount intValue] + 1];
            }
        }
        [super didChangeValueForKey:@"disc"];
    }
}

- (void) setIsAvailable:(NSNumber*)_isAvailable
{
    [super willChangeValueForKey:@"isAvailable"];
    BOOL oldValue = [[self primitiveValueForKey:@"isAvailable"] boolValue];
    BOOL newValue = [_isAvailable boolValue];
    Disc* disc = [self primitiveValueForKey:@"disc"];
    [self setPrimitiveValue:_isAvailable forKey:@"isAvailable"];
    if (disc && (oldValue != newValue)) {
        if (newValue) {
            disc.availableMediaCount = [NSNumber numberWithInt:[disc.availableMediaCount intValue] + 1];
        } else {
            disc.availableMediaCount = [NSNumber numberWithInt:[disc.availableMediaCount intValue] - 1];
        }
    }
    [super didChangeValueForKey:@"isAvailable"];
}

- (void) setIsLocal:(NSNumber*)_isLocal
{
    [super willChangeValueForKey:@"isLocal"];
    BOOL oldValue = [[self primitiveValueForKey:@"isLocal"] boolValue];
    BOOL newValue = [_isLocal boolValue];
    Disc* disc = [self primitiveValueForKey:@"disc"];
    [self setPrimitiveValue:_isLocal forKey:@"isLocal"];
    if (disc && (oldValue != newValue)) {
        if (newValue) {
            disc.localMediaCount = [NSNumber numberWithInt:[disc.localMediaCount intValue] + 1];
        } else {
            disc.localMediaCount = [NSNumber numberWithInt:[disc.localMediaCount intValue] - 1];
        }
    }
    [super didChangeValueForKey:@"isLocal"];
}

- (BOOL) isPhysicalMedia
{
    NSArray* a = [self.pathToFile componentsSeparatedByString:@"/"];
    if (3 == [a count] && 
        [@"" isEqualToString:[a objectAtIndex:0]] && 
        [@"Volumes" isEqualToString:[a objectAtIndex:1]]) {
        return YES;
    }
    else {
        return NO;
    }
}

@end
