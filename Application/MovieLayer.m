#import "MovieLayer.h"
#import "Movie.h"
#import "Disc.h"
#import "Media.h"

@implementation MovieLayer

@synthesize movie;

- (void) setMovie:(Movie*)_movie {
    movie = _movie;
    
    BOOL fullBreak = false;
    
    // Look for the first instance of a cover
    NSArray* discs = [movie.allDiscs allObjects];

    for (Disc* disc in discs) {
        NSArray* discMedia = [disc.allMedia allObjects];

        for (Media* media in discMedia) {
            if (media.url && [media.url length] > 0) {
                
                NSString* url = [[media.url stringByAppendingPathComponent:@"QuickLook"] stringByAppendingPathComponent:@"FrontCover.png"];
                url = [url stringByReplacingOccurrencesOfString:@"file:/localhost/" withString:@"file:///"];
                NSLog(@"%@", url);
                
                // Call out to it.
                NSURL* imageURL = [NSURL URLWithString:url];
                NSURLRequest* request = [NSURLRequest requestWithURL:imageURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5.0];
                
                if ([NSURLConnection canHandleRequest:request]) {
                    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
                    if(connection) {
                        imageData = [[NSMutableData data] retain];
                    }
                    
                    fullBreak = YES;
                    break;
                }
            }
        }
        
        if (fullBreak) {
            break;
        }        
    }
}

- (void) drawInContext:(CGContextRef)c
{
    CIImage* image = [self valueForKey:@"$image"];
    if (image) {
        CIFilter* scaleFilter = [CIFilter filterWithName:@"CILanczosScaleTransform"];
        [scaleFilter setDefaults];
        [scaleFilter setValue:image forKey:kCIInputImageKey];
        [scaleFilter setValue:[NSNumber numberWithFloat:self.bounds.size.height / image.extent.size.height] forKey:@"inputScale"];
        CIImage* scaledImage = [scaleFilter valueForKey:kCIOutputImageKey];

        CIContext* context = [CIContext contextWithCGContext:c options:nil];
        [context drawImage:scaledImage inRect:self.bounds fromRect:scaledImage.extent];
    } else {
        [super drawInContext:c];
    }
}

#pragma mark NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [imageData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError*)error
{
    [imageData release];
    NSLog(@"Connection error: %@", error);
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [imageData appendData:data];
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [self setValue:[CIImage imageWithData:imageData] forKey:@"$image"];
    [self setNeedsDisplay];
    
    [imageData release];
    imageData = nil;
    [connection release];
    connection = nil;
}


@end
