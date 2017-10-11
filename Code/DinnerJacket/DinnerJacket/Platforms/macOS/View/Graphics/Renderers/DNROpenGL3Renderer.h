//
//  DNROpenGLES2Renderer.h
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-05-03.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import "DNRBase.h"
#import "DNROpenGLRenderer.h"

/**
 Renderer for OpenGL 3.2 Core Profile API (macOS platform).
 */
@interface DNROpenGL3Renderer : NSObject <DNROpenGLRenderer>

- (id) initWithView:(DNROpenGLView *)view
  stencilBufferBits:(NSUInteger) stencilBits;


- (void) resizeWithWidth:(GLuint) width height:(GLuint) height;

@end

