//
//  DiscIdent.h
//  Library
//
//  Created by David Martorana on 8/19/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DiscIdent : NSObject {
    NSMutableData* receivedData;
    NSMutableString* urlString;
    NSString* pathToMovie;

    NSURL* discIdentURL;
    NSURLRequest* discIdentRequest;
    NSURLConnection* discIdentConnection;
}

- (BOOL) getMovieInfoFromDiscIdentUsingFingerprint:(NSString*)fingerprint pathToMovie:(NSString*)pathToMovie;


#pragma mark NSURLConnection deletgate methods

- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error; 
- (void) connectionDidFinishLoading:(NSURLConnection *)connection;

@end
