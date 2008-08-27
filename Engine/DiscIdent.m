//
//  DiscIdent.m
//  Library
//
//  Created by David Martorana on 8/19/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "DiscIdent.h"
#import "JSONKit/JSONKit.h"
#import "Movie.h"

NSString* const kDISC_IDENT_VERSION = @"v1";

@implementation DiscIdent


///
/// Check DiscIdent for a UPC code matching the fingerprint.  Also fill in other
/// DiscIdent information
///
- (BOOL) getMovieInfoFromDiscIdentUsingFingerprint:(Disc*)disc
{
    urlString = [NSMutableString stringWithString:@"http://discident.com/"];
    [urlString appendString:kDISC_IDENT_VERSION];
    [urlString appendString:@"/"];
    [urlString appendString:[disc fingerprint]];
    [urlString appendString:@"/"];
    
    pathToMovie = [[disc pathToFile] retain];
    
    receivedData = [[NSMutableData alloc] init];
    
    // Create our url
    discIdentURL = [NSURL URLWithString:urlString];
    discIdentRequest = [NSURLRequest requestWithURL:discIdentURL];
    discIdentConnection = [[NSURLConnection alloc] initWithRequest:discIdentRequest delegate:self startImmediately:YES];
    
    return FALSE;
}

- (void) dealloc
{
    [pathToMovie release];
    [receivedData release];
    
    [super dealloc];
}

///
/// A new response has begun to be received, prepare for it
///
- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response 
{
    // Reset the data
    [receivedData setLength:0];
}


///
/// When data is received, add to our buffer
///
- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data 
{
    [receivedData appendData:data];
}


///
/// The connection failed!
///
- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error 
{
    [receivedData setLength:0];
    
    // Examine the error
    
}


///
/// The connection finished loading, now do something with the 
/// data that we got.
///
- (void) connectionDidFinishLoading:(NSURLConnection *)connection 
{
    // Take the read data and do something with it
    
    // Get the string
    if ([receivedData length] > 0) {
        NSString* dataAsJSONString = [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding];
        NSDictionary* messageDict = [NSDictionary dictionaryWithJSON:dataAsJSONString];
                
        // Open up the current information we have
        NSDictionary* jsonFileDict = [NSDictionary dictionaryWithJSON:
                                    [NSString stringWithContentsOfFile:
                                     [pathToMovie stringByAppendingPathComponent:@"_Info.json"]
                                    ]];
        
        // Get the meta data
        NSMutableDictionary* metaDataWorkable; //= 
        id meta = [jsonFileDict objectForKey:@"meta"];
        
        if (meta && [meta isKindOfClass:[NSDictionary class]]) {
            metaDataWorkable = [NSMutableDictionary dictionaryWithDictionary:meta];
        }
        else {
            metaDataWorkable = [NSMutableDictionary dictionary];
        }
        
        // Add the contents of messageDict to here
        [metaDataWorkable setObject:messageDict forKey:@"com_discident"];
        
        // Add the meta data back into the basic dictionary
        NSMutableDictionary* newJsonFileDict = [NSMutableDictionary dictionaryWithDictionary:jsonFileDict];
        [newJsonFileDict setObject:[NSDictionary dictionaryWithDictionary:metaDataWorkable] forKey:@"meta"];
        
        // Now write out our changes
        NSData* toWrite = [NSData dataWithObjectAsJSON:[NSDictionary dictionaryWithDictionary:newJsonFileDict]];
        [toWrite writeToFile:[pathToMovie stringByAppendingPathComponent:@"_Info.json"] atomically:NO];
        
        [dataAsJSONString release];
    }
}


@end
