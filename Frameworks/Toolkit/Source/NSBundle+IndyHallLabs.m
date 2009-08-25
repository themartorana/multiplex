#import "NSBundle+IndyHallLabs.h"

@implementation NSBundle (IndyHallLabs)

+ (NSBundle*) bundleWithIdentifierStringFromLS:(NSString*)identifier
{
	CFURLRef bundleURL = NULL;
	LSFindApplicationForInfo(kLSUnknownCreator, (CFStringRef)identifier, NULL, NULL, &bundleURL);
	
	if (bundleURL != NULL && (NSURL*)bundleURL) {
		NSString* bundlePath = [(NSURL*)bundleURL path];
		NSBundle* bundle = [NSBundle bundleWithPath:bundlePath];
		
		CFRelease(bundleURL);
		
		return bundle;
	}
	else {
		return nil;
	}
}

- (NSString*) version
{
    return [[self infoDictionary] objectForKey:@"CFBundleVersion"];
}

- (NSString*) shortVersion
{
    return [[self infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}

@end