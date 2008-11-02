//
//  IndeterminateProgressIndicatorView.h
//  Multiplex
//
//  Created by David Martorana on 11/1/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class IndeterminateProgressIndicatorLayer;

@interface IndeterminateProgressIndicatorView : NSView {
    IndeterminateProgressIndicatorLayer* progressLayer;
}

@end
