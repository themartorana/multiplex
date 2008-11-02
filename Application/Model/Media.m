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
        [self setPrimitiveValue:_disc forKey:@"disc"];
        if (isAvailable) {
            if (disc) {
                disc.availableMediaCount = [NSNumber numberWithInt:[disc.availableMediaCount intValue] - 1];
            }
            if (_disc) {
                _disc.availableMediaCount = [NSNumber numberWithInt:[_disc.availableMediaCount intValue] + 1];
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

@end
