#import "DVDMediaSource.h"

static Media* newSpotlightItem(MDQueryRef query, MDItemRef item, void* mediaSource)
{
	return [[Media alloc] initWithMediaSource:mediaSource MDItemRef:item];
}

@implementation DVDMediaSource
@synthesize delegate;

- (void) dealloc
{
    if (query) {
        MDQueryStop(query);
        CFRelease(query);
    }
    [super dealloc];
}

- (void) start
{
    NSAssert(query == nil, @"DVDMediaSource already started.");
    
    NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];

	/*  Setup the query to find all of the PDF and CHM files on the discs 
	 *  directly connected to the computer.
	 */
	query = MDQueryCreate(NULL, (CFStringRef)@"kMDItemContentType == 'public.dvdmedia' || kMDItemContentType == 'dyn.ah62d4qmuhk2x43d0qv00n3dmqe'", NULL, NULL);
	MDQuerySetSearchScope(query, (CFArrayRef)[NSArray arrayWithObjects:(id)kMDQueryScopeComputer, nil], 0); 

	/*  Make sure that our progress and update notification handlers are 
	 *  properly registered.
	 */
	[notificationCenter addObserver:self selector:@selector(_queryDidUpdate:) name:(id)kMDQueryProgressNotification object:nil]; 
	[notificationCenter addObserver:self selector:@selector(_queryDidUpdate:) name:(id)kMDQueryDidFinishNotification object:nil]; 
	[notificationCenter addObserver:self selector:@selector(_queryDidUpdate:) name:(id)kMDQueryDidUpdateNotification object:nil]; 

	/*  Tell Spotlight how to create & track Item objects for us.  It will 
	 *  pass them back to us in our notifications instead of plain-jane 
	 *  MDItemRefs.
	 */
	MDQuerySetCreateResultFunction(query, (MDQueryCreateResultFunction)&newSpotlightItem, self, &kCFTypeArrayCallBacks);

	/*  Tell spotlight how much and how often we would like to be updated.
	 */
	MDQueryBatchingParams batchingParameters = {
		250,		// first_max_num
		0,			// first_max_ms
		250,		// progress_max_num
		0,			// progress_max_ms
		1,			// update_max_num
		0			// update_max_ms
	};
	MDQuerySetBatchingParameters(query, batchingParameters);

	/*	Execute the (live) query in an asynchronous manner.
	 */
	MDQueryExecute(query, kMDQueryWantsUpdates);
}

- (void) stop
{
    /*  Shutdown our spotlight notification handlers and disable the query.
     */
    NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter removeObserver:self];
    MDQueryDisableUpdates(query);
    
    /*  Notify our delegate that all of the items that we're currently tracking
     *  will no longer be available.
     */
    int count = MDQueryGetResultCount(query);
    if (count) {
        NSMutableArray* removedDiscs = [NSMutableArray arrayWithCapacity:count];
        while (count-- > 0) {
            [removedDiscs addObject:(Media*)MDQueryGetResultAtIndex(query, count)];
        }
        [delegate mediaSource:self didRemoveMedia:removedDiscs];
    }
    
    /*  Shutdown the query.
     */
    MDQueryStop(query);
    CFRelease(query);
    query = nil;
    mediaProcessed = 0;
}

- (void) _queryDidUpdate:(NSNotification*)notification
{
	NSDictionary* info = [notification userInfo];

	NSArray* removedDiscs = [info objectForKey:(id)kMDQueryUpdateRemovedItems];
	if (removedDiscs) {
        [delegate mediaSource:self didRemoveMedia:removedDiscs];
	}

	NSArray* changedDiscs = [info objectForKey:(id)kMDQueryUpdateChangedItems];
	if (changedDiscs) {
        [delegate mediaSource:self didUpdateMedia:changedDiscs];
	}

	if ([[notification name] isEqualTo:(id)kMDQueryProgressNotification]) {
		int imax = MDQueryGetResultCount(query);
        NSMutableArray* addedDiscs = [NSMutableArray array];
        for (int i = mediaProcessed; i < imax; i++) {
            [addedDiscs addObject:(Media*)MDQueryGetResultAtIndex(query, i)];
		}
        [delegate mediaSource:self didAddMedia:addedDiscs];
        mediaProcessed = imax;
	} else if ([[notification name] isEqualTo:(id)kMDQueryDidFinishNotification]) {
		//NSLog(@"finished");
	} else {
		NSArray* addedDiscs = [info objectForKey:(id)kMDQueryUpdateAddedItems];
		if (addedDiscs) {
            [delegate mediaSource:self didAddMedia:addedDiscs];
		}
	}
}

@end
