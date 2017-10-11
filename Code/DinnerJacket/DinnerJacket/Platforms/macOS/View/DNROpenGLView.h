//
//  DNRGLESView.h
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-05-03.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "DNRView.h"


/**
 */
@interface DNROpenGLView : NSOpenGLView <DNRView>

- (void) commonSetup;


@end
