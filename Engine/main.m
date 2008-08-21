#import <CoreFoundation/CoreFoundation.h>

int main(int argc, const char* argv[])
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    NSDictionary* info = [[NSBundle mainBundle] infoDictionary];
    NSString* principalClassName = [info objectForKey:@"NSPrincipalClass"];
    if (principalClassName) {
        Class principalClass = objc_getClass([principalClassName UTF8String]);
        if (principalClass) {
            [principalClass sharedApplication];
            [NSApp run];
            [NSApp release];
        }
    }
    [pool release];
    return 0;
}