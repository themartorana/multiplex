//
//  StartupSpinnerView.h
//  Multiplex
//
//  Created by David Martorana on 1/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class IndeterminateProgressIndicatorLayer;

@interface StartupSpinnerView : NSView {
    IndeterminateProgressIndicatorLayer* progressLayer;
    CALayer* backingLayer;
}

@end
