//
//  DNROpenGLESRenderer.h
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-05-03.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "DNRRenderer.h"                 // Adopted protocol

@class DNROpenGLView;


/**
 Specification of the protocol DNRRenderer. Intended for adoption of all
 renderers in the iOS platform (OpenGL ES APIs).
 */
@protocol DNROpenGLRenderer <DNRRenderer>


/// The main rendering context
@property (nonatomic, readonly) NSOpenGLContext* context;


/// The background rendering context
@property (nonatomic, readonly) NSOpenGLContext* backgroundContext;


///
- (id) initWithView:(DNROpenGLView *)view stencilBufferBits:(NSUInteger) stencilBits;


///
- (void) resizeWithWidth:(GLuint) width height:(GLuint) height;


///
- (BOOL) createFramebuffers;


@end


// .............................................................................
