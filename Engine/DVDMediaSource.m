#import "DVDMediaSource.h"
#import "Item.h"

static Item* newSpotlightItem(MDQueryRef query, MDItemRef item, void* info)
{
	return [[Item alloc] initWithMDItemRef:item];
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
        NSMutableArray* removedItems = [NSMutableArray arrayWithCapacity:count];
        while (count-- > 0) {
            [removedItems addObject:(Item*)MDQueryGetResultAtIndex(query, count)];
        }
        [delegate mediaSource:self didRemoveItems:removedItems];
    }
    
    /*  Shutdown the query.
     */
    MDQueryStop(query);
    CFRelease(query);
    query = nil;
    itemsProcessed = 0;
}

- (void) _queryDidUpdate:(NSNotification*)notification
{
	NSDictionary* info = [notification userInfo];

	NSArray* removedItems = [info objectForKey:(id)kMDQueryUpdateRemovedItems];
	if (removedItems) {
        [delegate mediaSource:self didRemoveItems:removedItems];
	}

	NSArray* changedItems = [info objectForKey:(id)kMDQueryUpdateChangedItems];
	if (changedItems) {
        [delegate mediaSource:self didUpdateItems:changedItems];
	}

	if ([[notification name] isEqualTo:(id)kMDQueryProgressNotification]) {
		int imax = MDQueryGetResultCount(query);
        NSMutableArray* addedItems = [NSMutableArray array];
        for (int i = itemsProcessed; i < imax; i++) {
            [addedItems addObject:(Item*)MDQueryGetResultAtIndex(query, i)];
		}
        [delegate mediaSource:self didAddItems:addedItems];
        itemsProcessed = imax;
	} else if ([[notification name] isEqualTo:(id)kMDQueryDidFinishNotification]) {
		//NSLog(@"finished");
	} else {
		NSArray* addedItems = [info objectForKey:(id)kMDQueryUpdateAddedItems];
		if (addedItems) {
            [delegate mediaSource:self didAddItems:addedItems];
		}
	}
}

@end
