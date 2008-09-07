#import "JSONKit/JSONKit.h"
#import "Engine.h"
#import "Disc.h"
#import "DVDMediaSource.h"
#import "PhysicalMediaSource.h"
#import "DiscIdent.h"
#import "Amazon.h"
#import "MessageProtocol.h"
#import "NSDictionary+KeyPaths.h"

static NSString* const kAmazonAccessKey = @"01Y2NSCMDJ3VJXTCBTR2";

@implementation Engine

- (id) init
{
    if (self = [super init]) {
        discsByFingerprint = [[NSMutableDictionary alloc] init];
        infoDictionariesByFingerprint = [[NSMutableDictionary alloc] init];
        
        // Set up the protocol
        protocol = [[MessageProtocol protocolWithDelegate:self fileHandleForReading:[NSFileHandle fileHandleWithStandardInput] fileHandleForWriting:[NSFileHandle fileHandleWithStandardOutput]] retain];
    }
    return self;
}

- (void) dealloc
{    
    [protocol release];
    [discsByFingerprint release];
    [infoDictionariesByFingerprint release];
    [super dealloc];
}

- (void) run
{
    /*  Register our media sources.  Later, this can be done more "plugin" 
     *  style.
     */
    NSArray* mediaSources = [NSArray arrayWithObjects:
        [[DVDMediaSource alloc] init],
        [[PhysicalMediaSource alloc] init],
        nil
    ];
    
    /*  Set ourselves as the media source's delegate, and then start it up.
     */
    for (id<MediaSource> mediaSource in mediaSources) {
        [mediaSource setDelegate:self];
        [mediaSource start];
    }

    /*  Process our message loop unil we're told to stop.
     */
    [super run];

    /*  Shutdown all of our media sources.
     */
    for (id<MediaSource> mediaSource in mediaSources) {
        [mediaSource stop];
    }
}

- (NSMutableDictionary*) determineChangedKeysUsingDictionary:(NSMutableDictionary*)ad andDictionary:(NSMutableDictionary*)bd
{
    NSMutableDictionary* newKeys = nil;
    NSEnumerator* a = [[[ad allKeys] sortedArrayUsingSelector:@selector(compare:)] objectEnumerator];
    NSEnumerator* b = [[[bd allKeys] sortedArrayUsingSelector:@selector(compare:)] objectEnumerator];
    NSString* ak = [a nextObject], *bk = [b nextObject];
    id bv = [bd objectForKey:bk];
    while (bk && ak) {
        int v = [bk compare:ak];
        if (v > 0) {
            ak = [a nextObject];
        } else if (v < 0) {
            if (!newKeys) {
                newKeys = [NSMutableDictionary dictionary];
            }
            [newKeys setObject:[bd objectForKey:bk] forKey:bk];
            bk = [b nextObject];
            bv = [bd objectForKey:bk];
        } else if (v == 0) {
            if (![bv isEqual:[ad objectForKey:bk]]) {
                if (!newKeys) {
                    newKeys = [NSMutableDictionary dictionary];
                }
                [newKeys setObject:[bd objectForKey:bk] forKey:bk];
            }
            bk = [b nextObject];
            bv = [bd objectForKey:bk];
        }
    }
    if (bk) {
        if (!newKeys) {
            newKeys = [NSMutableDictionary dictionary];
        }
        do {
            [newKeys setObject:bv forKey:bk];
        } while ((bk = [b nextObject]) && (bv = [bd objectForKey:bk]));
    }
    return newKeys;
}

- (void) mediaSource:(id<MediaSource>)mediaSource didAddMedia:(NSArray*)arrayOfMedia
{
    NSMutableDictionary* addsByFingerprint = [NSMutableDictionary dictionary];
    NSMutableDictionary* updatesByFingerprint = [NSMutableDictionary dictionary];
    for (Media* media in arrayOfMedia) {
        NSString* mediaFingerprint = [media fingerprint];
        media.url = [NSURL fileURLWithPath:[media pathToFile] isDirectory:YES];
        if (mediaFingerprint) {
            /*  Attempt to add this disc to a movie using the new fingerprint.
             *  If a movie doesn't exist, create one and treat it like an add,
             *  otherwise, we can consider this a normal update to an existing
             *  movie.
             */
            NSMutableDictionary* addsOrUpdatesByFingerprint;
            Disc* disc = [discsByFingerprint objectForKey:mediaFingerprint];
            if (!disc) {
                [discsByFingerprint setObject:
                    disc = [[Disc alloc] initWithFingerprint:mediaFingerprint media:media]
                    forKey:mediaFingerprint
                ];
                addsOrUpdatesByFingerprint = addsByFingerprint;
                
                if (![addsOrUpdatesByFingerprint valueForKeyPath:@"meta.discident"]) {
                    [DiscIdentQuery queryWithFingerprint:mediaFingerprint delegate:self userInfo:[disc retain] startImmediately:YES];
                }
            } else {
                [disc addMedia:media];
                addsOrUpdatesByFingerprint = updatesByFingerprint;
            }
            
            /*
             */
            NSMutableDictionary* infoForFingerprint = [addsOrUpdatesByFingerprint objectForKey:mediaFingerprint];
            if (!infoForFingerprint) {
                [addsOrUpdatesByFingerprint setObject:
                    infoForFingerprint = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        [NSMutableArray arrayWithObject:[media.url absoluteString]],
                        @"urls",
                        nil
                    ]
                    forKey:
                        mediaFingerprint
                ];
            } else {
                [[infoForFingerprint objectForKey:@"urls"] addObject:[media.url absoluteString]];
            }
            
            /*  Read in the info dictionary, and merge it with any that we've
             *  already loaded.
             */
            NSMutableDictionary* flattenedDiscInfoDictionary = [[disc infoDictionary] flattenToKeyPathsAndObjects];
            NSMutableDictionary* flattenedMediaInfoDictionary = [[media infoDictionary] flattenToKeyPathsAndObjects];
            NSMutableDictionary* newKeyPathsAndObjects = [self determineChangedKeysUsingDictionary:flattenedDiscInfoDictionary andDictionary:flattenedMediaInfoDictionary];
            if ([newKeyPathsAndObjects count]) {
                if (!disc.infoDictionary) {
                    disc.infoDictionary = [NSDictionary dictionaryWithExpandedKeyPathsAndObjects:newKeyPathsAndObjects];
                } else {
                    [flattenedDiscInfoDictionary addEntriesFromDictionary:newKeyPathsAndObjects];
                    disc.infoDictionary = [NSDictionary dictionaryWithExpandedKeyPathsAndObjects:flattenedDiscInfoDictionary];
                }
                NSMutableDictionary* infoForFingerprint = [addsOrUpdatesByFingerprint objectForKey:mediaFingerprint];
                if (!infoForFingerprint) {
                    [addsOrUpdatesByFingerprint setObject:infoForFingerprint = [NSDictionary dictionaryWithExpandedKeyPathsAndObjects:newKeyPathsAndObjects] forKey:mediaFingerprint];
                } else {
                    NSMutableDictionary* flattenedInfoForFingerprint = [infoForFingerprint flattenToKeyPathsAndObjects];
                    [flattenedInfoForFingerprint addEntriesFromDictionary:newKeyPathsAndObjects];
                    [addsOrUpdatesByFingerprint setObject:infoForFingerprint = [NSDictionary dictionaryWithExpandedKeyPathsAndObjects:flattenedInfoForFingerprint] forKey:mediaFingerprint];
                }
            }
        } else {
            static NSString* pathToMDImport = @"/usr/bin/mdimport";
            [NSTask launchedTaskWithLaunchPath:pathToMDImport arguments:[NSArray arrayWithObjects:pathToMDImport, [media pathToFile], nil]];
        }
    }

    /*  Build and send the message.
     */
    NSMutableDictionary* message = [NSMutableDictionary dictionary];
    if ([addsByFingerprint count]) {
        [message setObject:addsByFingerprint forKey:@"add"];
    }
    if ([updatesByFingerprint count]) {
        [message setObject:updatesByFingerprint forKey:@"update"];
    }
    if ([message count]) {
        [protocol sendMessage:message];
    }
}

- (void) mediaSource:(id<MediaSource>)mediaSource didUpdateMedia:(NSArray*)arrayOfMedia
{
    NSMutableDictionary* addsByFingerprint = [NSMutableDictionary dictionary];
    NSMutableDictionary* updatesByFingerprint = [NSMutableDictionary dictionary];
    NSMutableDictionary* deletesByFingerprint = [NSMutableDictionary dictionary];
    for (Media* media in arrayOfMedia) {
        NSString* discFingerprint = [[media disc] fingerprint];
        NSString* mediaFingerprint = [media fingerprint];
        NSMutableDictionary* addsOrUpdatesByFingerprint = nil;
        
        if ([mediaFingerprint isEqualToString:discFingerprint] && [[media url] isEqual:[NSURL fileURLWithPath:media.pathToFile]]) {
            addsOrUpdatesByFingerprint = updatesByFingerprint;
        } else {
            /*  Remove this disc from the movie it used to match up with.  If
             *  that causes there to be no more discs for that movie, then 
             *  we'll need to delete it.
             */
            if (discFingerprint) {
                Disc* disc = [discsByFingerprint objectForKey:discFingerprint];
                [disc removeMedia:media];
                if (![disc hasDisc]) {
                    [discsByFingerprint removeObjectForKey:discFingerprint];
                }

                NSMutableDictionary* infoForFingerprint = [deletesByFingerprint objectForKey:mediaFingerprint];
                if (!infoForFingerprint) {
                    [deletesByFingerprint setObject:
                        [NSMutableDictionary dictionaryWithObjectsAndKeys:
                            [NSMutableArray arrayWithObject:[media.url absoluteString]],
                            @"urls",
                            nil
                        ]
                        forKey:
                            mediaFingerprint
                    ];
                } else {
                    [[infoForFingerprint objectForKey:@"urls"] addObject:[media.url absoluteString]];
                }
            }

            [media reload];

            /*  Attempt to add this disc to a movie using the new fingerprint.
             *  If a movie doesn't exist, create one and treat it like an add,
             *  otherwise, we can consider this a normal update to an existing
             *  movie.
             */
            media.url = [NSURL fileURLWithPath:media.pathToFile isDirectory:YES];
            if (mediaFingerprint) {
                Disc* disc = [discsByFingerprint objectForKey:mediaFingerprint];
                if (!disc) {
                    [discsByFingerprint setObject:
                        disc = [[Disc alloc] initWithFingerprint:mediaFingerprint media:media]
                        forKey:mediaFingerprint
                    ];
                    addsOrUpdatesByFingerprint = addsByFingerprint;
                } else {
                    [disc addMedia:media];
                    addsOrUpdatesByFingerprint = updatesByFingerprint;
                }
            
                NSMutableDictionary* infoForFingerprint = [addsOrUpdatesByFingerprint objectForKey:mediaFingerprint];
                if (!infoForFingerprint) {
                    [addsOrUpdatesByFingerprint setObject:
                        infoForFingerprint = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                            [NSMutableArray arrayWithObject:[media.url absoluteString]],
                            @"urls",
                            nil
                        ]
                        forKey:
                            mediaFingerprint
                    ];
                } else {
                    [[infoForFingerprint objectForKey:@"urls"] addObject:[media.url absoluteString]];
                }
            }
        }

        /*  Read in the info dictionary, and merge it with any that we've
         *  already loaded.
         */
        if (addsOrUpdatesByFingerprint) {
            Disc* disc = media.disc;
            NSMutableDictionary* flattenedDiscInfoDictionary = [[disc infoDictionary] flattenToKeyPathsAndObjects];
            NSMutableDictionary* flattenedMediaInfoDictionary = [[media infoDictionary] flattenToKeyPathsAndObjects];
            NSMutableDictionary* newKeyPathsAndObjects = [self determineChangedKeysUsingDictionary:flattenedDiscInfoDictionary andDictionary:flattenedMediaInfoDictionary];
            if ([newKeyPathsAndObjects count]) {
                if (!disc.infoDictionary) {
                    disc.infoDictionary = [NSDictionary dictionaryWithExpandedKeyPathsAndObjects:newKeyPathsAndObjects];
                } else {
                    [flattenedDiscInfoDictionary addEntriesFromDictionary:newKeyPathsAndObjects];
                    disc.infoDictionary = [NSDictionary dictionaryWithExpandedKeyPathsAndObjects:flattenedDiscInfoDictionary];
                }
                NSMutableDictionary* infoForFingerprint = [addsOrUpdatesByFingerprint objectForKey:mediaFingerprint];
                if (!infoForFingerprint) {
                    [addsOrUpdatesByFingerprint setObject:infoForFingerprint = [NSDictionary dictionaryWithExpandedKeyPathsAndObjects:newKeyPathsAndObjects] forKey:mediaFingerprint];
                } else {
                    NSMutableDictionary* flattenedInfoForFingerprint = [infoForFingerprint flattenToKeyPathsAndObjects];
                    [flattenedInfoForFingerprint addEntriesFromDictionary:newKeyPathsAndObjects];
                    [addsOrUpdatesByFingerprint setObject:infoForFingerprint = [NSDictionary dictionaryWithExpandedKeyPathsAndObjects:flattenedInfoForFingerprint] forKey:mediaFingerprint];
                }
            }
        }
    }

    /*  Build and send the message.
     */
    NSMutableDictionary* message = [NSMutableDictionary dictionary];
    if ([addsByFingerprint count]) {
        [message setObject:addsByFingerprint forKey:@"add"];
    }
    if ([updatesByFingerprint count]) {
        [message setObject:updatesByFingerprint forKey:@"update"];
    }
    if ([deletesByFingerprint count]) {
        [message setObject:deletesByFingerprint forKey:@"delete"];
    }
    if ([message count]) {
        [protocol sendMessage:message];
    }
}

- (void) mediaSource:(id<MediaSource>)mediaSource didRemoveMedia:(NSArray*)arrayOfMedia
{
    NSMutableDictionary* deletesByFingerprint = [NSMutableDictionary dictionary];
    for (Media* media in arrayOfMedia) {
        Disc* disc = [media disc];
        if (disc) {
            NSString* fingerprint = [media fingerprint];
            [disc removeMedia:media];
            if (![disc hasDisc]) {
                [discsByFingerprint removeObjectForKey:fingerprint];
            }
            
            NSMutableDictionary* infoForFingerprint = [deletesByFingerprint objectForKey:fingerprint];
            if (!infoForFingerprint) {
                [deletesByFingerprint setObject:
                    [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        [NSMutableArray arrayWithObject:[media.url absoluteString]],
                        @"urls",
                        nil
                    ]
                    forKey:
                        fingerprint
                ];
            } else {
                [[infoForFingerprint objectForKey:@"urls"] addObject:[media.url absoluteString]];
            }
        }
    }

    /*  Build and send the message.
     */
    if ([deletesByFingerprint count]) {
        NSMutableDictionary* message = [NSMutableDictionary dictionaryWithObjectsAndKeys:
            deletesByFingerprint,
            @"delete",
            nil
        ];
        [protocol sendMessage:message];
    }
}


#pragma mark MessageProtocolDelegate

- (void) protocol:(MessageProtocol*)protocol didReceiveMessage:(NSDictionary*)messageDict
{
    /* TODO: Implement me */
}


#pragma mark DiscIdentQueryDelegate

- (void) discIdentQuery:(DiscIdentQuery*)query didFailWithError:(NSError*)error userInfo:(Disc*)disc
{
    [disc release];
}

- (void) discIdentQuery:(DiscIdentQuery*)query didReceiveResponse:(NSDictionary*)response userInfo:(Disc*)disc
{
    NSMutableDictionary* flattenedDiscInfoDictionary = [[disc infoDictionary] flattenToKeyPathsAndObjects];
    NSMutableDictionary* flattenedMediaInfoDictionary = [[NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithObject:response forKey:@"discident"] forKey:@"meta"] flattenToKeyPathsAndObjects];
    NSMutableDictionary* newKeyPathsAndObjects = [self determineChangedKeysUsingDictionary:flattenedDiscInfoDictionary andDictionary:flattenedMediaInfoDictionary];
    if ([newKeyPathsAndObjects count]) {
        NSMutableDictionary* mergedInfo = nil;
        if (!disc.infoDictionary) {
            mergedInfo = [NSMutableDictionary dictionaryWithExpandedKeyPathsAndObjects:newKeyPathsAndObjects];
        } else {
            [flattenedDiscInfoDictionary addEntriesFromDictionary:newKeyPathsAndObjects];
            mergedInfo = [NSDictionary dictionaryWithExpandedKeyPathsAndObjects:flattenedDiscInfoDictionary];
        }
        
        NSMutableDictionary* movie = nil;
        NSMutableArray* synthetic = nil;
        if (nil == (movie = [mergedInfo objectForKey:@"movie"])) {
            [mergedInfo setObject:movie = [NSMutableDictionary dictionaryWithObject:synthetic = [NSMutableArray array] forKey:@"synthetic"] forKey:@"movie"];
        } else if (nil == (synthetic = [movie objectForKey:@"synthetic"])) {
            [movie setObject:synthetic = [NSMutableArray array] forKey:@"synthetic"];
        }

        NSMutableDictionary* message = [NSMutableDictionary dictionaryWithObject:[NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithExpandedKeyPathsAndObjects:newKeyPathsAndObjects] forKey:disc.fingerprint] forKey:@"update"];
        [protocol sendMessage:message];
    }
    
    NSString* gtin = [newKeyPathsAndObjects objectForKey:@"meta.discident.gtin"];
    if ([gtin characterAtIndex:0] == '0') {
        [AmazonQuery queryWithAccessKey:kAmazonAccessKey ean:[gtin substringFromIndex:1] delegate:self userInfo:[disc retain] startImmediately:YES];
    }
    [disc release];
}


#pragma mark AmazonQueryDelegate

- (void) amazonQuery:(AmazonQuery*)query didFailWithError:(NSError*)error userInfo:(Disc*)disc
{
    [disc release];
}

- (void) amazonQuery:(AmazonQuery*)query didReceiveResponse:(NSDictionary*)response userInfo:(Disc*)disc
{
    NSMutableDictionary* flattenedDiscInfoDictionary = [[disc infoDictionary] flattenToKeyPathsAndObjects];
    NSMutableDictionary* flattenedMediaInfoDictionary = [[NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithObject:response forKey:@"amazon"] forKey:@"meta"] flattenToKeyPathsAndObjects];
    NSMutableDictionary* newKeyPathsAndObjects = [self determineChangedKeysUsingDictionary:flattenedDiscInfoDictionary andDictionary:flattenedMediaInfoDictionary];
    if ([newKeyPathsAndObjects count]) {
        if (!disc.infoDictionary) {
            disc.infoDictionary = [NSDictionary dictionaryWithExpandedKeyPathsAndObjects:newKeyPathsAndObjects];
        } else {
            [flattenedDiscInfoDictionary addEntriesFromDictionary:newKeyPathsAndObjects];
            disc.infoDictionary = [NSDictionary dictionaryWithExpandedKeyPathsAndObjects:flattenedDiscInfoDictionary];
        }
        NSMutableDictionary* message = [NSMutableDictionary dictionaryWithObject:[NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithExpandedKeyPathsAndObjects:newKeyPathsAndObjects] forKey:disc.fingerprint] forKey:@"update"];
        [protocol sendMessage:message];
    }
    [disc release];
}

@end


