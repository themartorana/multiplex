//
//  NSStringToAndFromNSAttributedString.m
//  Multiplex
//
//  Created by David Martorana on 10/6/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NSDescriptionValueTransformer.h"

@implementation NSDescriptionValueTransformer

+ (Class)transformedValueClass { return [NSAttributedString class]; }

+ (BOOL)allowsReverseTransformation { return YES; }

- (NSAttributedString*) transformedValue:(NSString*)value {
    if (value) {
        NSData* stringData = [value dataUsingEncoding:NSUTF8StringEncoding];
        NSMutableAttributedString* attString = [[NSMutableAttributedString alloc] initWithHTML:stringData documentAttributes:NULL];
        
        return attString;
    }
    else {
        return nil;
    }
}

- (NSString*) reverseTransformedValue:(NSAttributedString*)value
{
    if (value) {
        NSRange dataRange = NSMakeRange(0, [value length]);
        NSDictionary* documentAttributes = [NSDictionary dictionaryWithObject:NSHTMLTextDocumentType forKey:NSDocumentTypeDocumentAttribute];
        
        NSError* error = nil;
        NSData* htmlData = [value dataFromRange:dataRange documentAttributes:documentAttributes error:&error];
        
        NSString* htmlString = [[[NSString alloc] initWithData:htmlData encoding:NSUTF8StringEncoding] autorelease];
        
        return htmlString;
    }
    else {
        return nil;
    }
}

@end
