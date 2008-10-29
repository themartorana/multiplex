#import <Cocoa/Cocoa.h>

@class BoxArt;

@interface Movie : NSManagedObject {
}

@property (retain) NSString* aspectRatio;
@property (retain) NSString* genre;
@property (retain) NSString* gtin;
@property (retain) NSNumber* productionYear;
@property (retain) NSString* review;
@property (retain) NSString* studio;
@property (retain) NSString* synopsis;
@property (retain) NSString* title;
@property (retain) NSNumber* runningTime;
@property (retain) NSNumber* regionCode;
@property (retain) NSDate* premiereDate;
@property (retain) NSDate* releaseDate;
@property (retain) NSDate* theatricalReleaseDate;
@property (retain) NSString* rating;
@property (retain) BoxArt* boxArt;
@property (retain) NSNumber* starRating;

@property (readonly) NSMutableSet* allDiscs;

@end
