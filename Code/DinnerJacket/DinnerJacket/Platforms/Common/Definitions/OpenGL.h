//
//  OpenGL.h
//  DinnerJacket
//
//  Created by Nicolás Miari on 2016/09/10.
//  Copyright © 2016 Nicolás Miari. All rights reserved.
//

#ifndef OpenGL_h
#define OpenGL_h

#include "TargetConditionals.h"

/** 
 Imports the appropriate headers so that the basic OpenGL types (GLfloat,
 etc.) re available, regardless of the platform.
*/

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR

#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>

#elif TARGET_OS_OSX

#include <OpenGL/gl3.h>
#include <OpenGL/glu.h>

#endif


#endif /* OpenGL_h */
