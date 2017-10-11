//
//  DNROpenGLESRenderer.h
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-05-03.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import <OpenGLES/EAGL.h>               // EAGLContext
#import <QuartzCore/QuartzCore.h>       // CAEAGLLayer

#import "DNRRenderer.h"                 // Adopted protocol



@class DNROpenGLESView;


/**
 Specification of the protocol DNRRenderer. Intended for adoption of all
 renderers in the iOS platform (OpenGL ES APIs).
 */
@protocol DNROpenGLESRenderer <DNRRenderer>


/// The main rendering context
@property (nonatomic, readonly) EAGLContext* context;


/// The background rendering context
@property (nonatomic, readonly) EAGLContext* backgroundContext;


///
- (id) initWithView:(DNROpenGLESView *)view stencilBufferBits:(NSUInteger) stencilBits;


///
- (BOOL) resizeFromLayer:(CAEAGLLayer *)layer;


///
- (BOOL) createFramebuffers;


@end


// .............................................................................
