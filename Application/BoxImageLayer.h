//
//  BoxImageLayer.h
//  Multiplex
//
//  Created by David Martorana on 9/18/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import "IndeterminateProgressIndicatorLayer.h"

@interface BoxImageLayer : CATiledLayer {
    IndeterminateProgressIndicatorLayer* idpil;
}

- (void) startSpinner;
- (void) stopSpinner;

@end
