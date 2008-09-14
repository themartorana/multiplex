#import "AmazonQuery.h"

#pragma mark -
@interface AmazonQuery (Private)
- (void) _fireDidFailWithError:(NSError*)error;
- (void) _fireDidReceiveResponse:(NSDictionary*)response;
@end

#pragma mark -
@implementation AmazonQuery
@synthesize delegate;
@synthesize ean;
@synthesize userInfo;

+ (id) queryWithAccessKey:(NSString*)accessKey ean:(NSString*)ean
{
    return [[[AmazonQuery alloc] initWithAccessKey:accessKey ean:ean] autorelease];
}

+ (id) queryWithAccessKey:(NSString*)accessKey ean:(NSString*)ean delegate:(id)delegate userInfo:(void*)userInfo startImmediately:(BOOL)startImmediately
{
    NSAssert(delegate, @"The delegate must not be nil.");
    AmazonQuery* query = [AmazonQuery queryWithAccessKey:accessKey ean:ean];
    query.delegate = delegate;
    query.userInfo = userInfo;
    if (startImmediately) {
        [query start];
    }
    return query;
}

- (id) initWithAccessKey:(NSString*)_accessKey ean:(NSString*)_ean
{
    NSAssert(_accessKey, @"accessKey must not be nil.");
    NSAssert(_ean, @"ean must not be nil.");
    NSAssert([_ean length] == 13, @"ean must not be exactly 13 digits long.");
    if (self = [super init]) {
        accessKey = [_accessKey retain];
        ean = [_ean retain];
    }
    return self;
}

- (void) dealloc
{
    [accessKey release];
    [ean release];
    [connection release];
    [request release];
    [receivedData release];
    [super dealloc];
}

- (void) start
{
    NSAssert(!connection, @"This query has already been started.");
    NSMutableString* url = [NSMutableString stringWithCapacity:1024];
    [url appendFormat:
        @"http://webservices.amazon.com/onca/xml?Service=AWSECommerceService" \
         "&SubscriptionId=%@" \
         "&Operation=ItemLookup" \
         "&ResponseGroup=Small,ItemAttributes,Images,EditorialReview" \
         "&IdType=EAN"
         "&SearchIndex=DVD",
         accessKey
    ];
    [url appendFormat:@"&ItemId=%@", ean];
    request = [[NSURLRequest requestWithURL:[NSURL URLWithString:url]] retain];
    connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
}

- (void) cancel
{
    [connection cancel];
}

@end

#pragma mark -
@implementation AmazonQuery (NSURLConnectionDelegate)

- (void) connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response 
{
    receivedData = [[NSMutableData alloc] init];
}

- (void) connection:(NSURLConnection*)connection didReceiveData:(NSData*)data 
{
    [receivedData appendData:data];
}

- (void) connection:(NSURLConnection*)connection didFailWithError:(NSError*)error 
{
    [receivedData release];
    receivedData = nil;
    [self _fireDidFailWithError:error];
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection 
{
    NSMutableDictionary* response = nil;
    NSError* error = nil;
    if ([receivedData length] > 0) {
        NSXMLDocument* xml = [[NSXMLDocument alloc] initWithData:receivedData options:NSXMLDocumentTidyXML error:&error];
        NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] initWithDateFormat:@"%Y-%m-%d" allowNaturalLanguage:NO];
        NSNumberFormatter* numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setNumberStyle:NSNumberFormatterNoStyle];
        if (!error) @try {
            /*  Process any "soft" errors; EAN not found, etc.  If the movie has 
             *  any other EAN, then re-queue the item for lookup using one of 
             *  those.
             */
            NSArray* softErrors = [[xml rootElement] objectsForXQuery:
               @"for $p in ./Items/Request/Errors/Error[Code=\"AWS.InvalidParameterValue\"]/Message\n" \
                "return\n" \
                "<Error>{ string($p) }</Error>\n"
                constants:nil
                error:&error
            ];
            if (softErrors && [softErrors count]) {
                /* TODO: Handle this?  */
            }

            /*  Process any returned items using an XQuery to separate the stuff 
             *  we actually care about from the stuff we don't.  The items are
             *  ordered alphabetically to make the following section a little 
             *  easier to follow.
             */
            NSArray* items = [[xml rootElement] objectsForXQuery:
               @"for $p in ./Items/Item\n" \
                "return\n" \
                "<movie"
                " _id='{ string($p/ASIN) }'" \
                " _detail_page_url='{ string($p/DetailPageURL) }'" \
                " _cover_image_url='{ string($p/LargeImage/URL) }'" \
                " aspect_ratio='{ string($p/ItemAttributes/AspectRatio) }'" \
                " audience_rating='{ string($p/ItemAttributes/AudienceRating) }'" \
                " actors='{ string-join(for $n in $p/ItemAttributes/Actor return string($n), '|') }'"\
                " review='{ string($p/EditorialReviews/EditorialReview[Source=\"Amazon.com\"][1]/Content) }'" \
                " release_date='{ string($p/ItemAttributes/ReleaseDate) }'" \
                " studio='{ string($p/ItemAttributes/Publisher) }'" \
                " synopsis='{ string($p/EditorialReviews/EditorialReview[Source=\"Description\" or Source=\"Product Description\" or Source][1]/Content) }'" \
                " theatrical_release_date='{ string($p/ItemAttributes/TheatricalReleaseDate) }'" \
                " title='{ string($p/ItemAttributes/Title) }'" \
                " region_code='{ string($p/ItemAttributes/RegionCode) }'" \
                " running_time='{ string($p/ItemAttributes/RunningTime) }'" \
                "/>\n"
                constants:nil
                error:&error
            ];
            if ([items count]) {
                NSXMLElement* item = [items objectAtIndex:0];
                response = [NSMutableDictionary dictionary];
                
                NSString* amazonId = [[item attributeForName:@"_id"] stringValue];
                if ([amazonId length]) {
                    [response setObject:amazonId forKey:@"_id"];
                }
                
                NSString* coverImageURL = [[item attributeForName:@"_cover_image_url"] stringValue];
                if ([coverImageURL length]) {
                    [response setObject:coverImageURL forKey:@"_coverImageURL"];
                }
                
                NSString* detailPageURL = [[item attributeForName:@"_detail_page_url"] stringValue];
                if ([detailPageURL length]) {
                    [response setObject:detailPageURL forKey:@"_detailPageURL"];
                }
                
                NSString* aspectRatio = [[item attributeForName:@"aspect_ratio"] stringValue];
                if ([aspectRatio length]) {
                    [response setObject:aspectRatio forKey:@"aspectRatio"];
                }
                
                NSString* audienceRating = [[item attributeForName:@"audience_rating"] stringValue];
                if ([audienceRating length]) {
                    [response setObject:audienceRating forKey:@"audienceRating"];
                }
                
                NSArray* actors = [[[item attributeForName:@"actors"] stringValue] componentsSeparatedByString:@"|"];
                if ([actors count]) {
                    [response setObject:actors forKey:@"actors"];
                }
                
                NSString* synopsis = [[item attributeForName:@"synopsis"] stringValue];
                if ([synopsis length]) {
                    [response setObject:synopsis forKey:@"synopsis"];
                }

                NSString* review = [[item attributeForName:@"review"] stringValue];
                if ([review length]) {
                    [response setObject:review forKey:@"review"];
                }
                
                NSDate* releaseDate = [NSDate dateWithNaturalLanguageString:[[item attributeForName:@"release_date"] stringValue]];      
                if (releaseDate) {
                    [response setObject:[dateFormatter stringFromDate:releaseDate] forKey:@"releaseDate"];
                }
                
                NSDate* theatricalReleaseDate = [NSDate dateWithNaturalLanguageString:[[item attributeForName:@"theatrical_release_date"] stringValue]];      
                if (theatricalReleaseDate) {
                    [response setObject:[dateFormatter stringFromDate:theatricalReleaseDate] forKey:@"theatricalReleaseDate"];
                }
                
                NSString* studio = [[item attributeForName:@"studio"] stringValue];
                if ([studio length]) {
                    [response setObject:studio forKey:@"studio"];
                }
                
                NSString* title = [[item attributeForName:@"title"] stringValue];
                if ([title length]) {
                    [response setObject:title forKey:@"title"];
                }
                
                NSString* regionCode = [[item attributeForName:@"region_code"] stringValue];
                if ([regionCode length]) {
                    int value = [[numberFormatter numberFromString:regionCode] intValue];
                    if (value >= 0 && value <= 8) {
                        [response setObject:[NSNumber numberWithInt:value] forKey:@"regionCode"];
                    }
                }
                
                NSString* runningTime = [[item attributeForName:@"running_time"] stringValue];
                if ([runningTime length]) {
                    [response setObject:[numberFormatter numberFromString:runningTime] forKey:@"runningTime"];
                }
            }
        } @catch (id exception) {
            NSLog(@"AmazonQuery:  Exception during parse -- %@", exception);
        }
        [dateFormatter release];
        [numberFormatter release];
        [xml release];
    }

    if (![response count] || error) {
        [self _fireDidFailWithError:error];
    } else {
        [self _fireDidReceiveResponse:response];
    }
}

@end

#pragma mark -
@implementation AmazonQuery (Private)

- (void) _fireDidFailWithError:(NSError*)error
{
    if ([delegate respondsToSelector:@selector(amazonQuery:didFailWithError:userInfo:)]) {
        @try {
            [delegate amazonQuery:self didFailWithError:error userInfo:userInfo];
        } @catch (id _exception) {
            NSLog(@"AmazonQuery: Exception during amazonQuery:didFailWithError: -- %@", _exception);
        }
    }
}

- (void) _fireDidReceiveResponse:(NSDictionary*)response  
{
    if ([delegate respondsToSelector:@selector(amazonQuery:didReceiveResponse:userInfo:)]) {
        @try {
            [delegate amazonQuery:self didReceiveResponse:response userInfo:userInfo];
        } @catch (id _exception) {
            NSLog(@"AmazonQuery: Exception during amazonQuery:didReceiveResponse: -- %@", _exception);
        }
    }
}

@end
