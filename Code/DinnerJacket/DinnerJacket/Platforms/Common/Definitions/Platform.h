//
//  Platform.h
//  DinnerJacket
//
//  Created by Nicolás Miari on 2016/09/10.
//  Copyright © 2016 Nicolás Miari. All rights reserved.
//

#ifndef Platform_h
#define Platform_h

/**
 Platform-dependent definitions (TODO: Implement Mac support).
 */

#include "TargetConditionals.h"

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR

// .............................................................................

#define DNRPlatformPhone

#include <OpenGLES/ES2/gl.h>    // TODO: Migrate to ES 3 (or better, Metal!) some day.
#include <OpenGLES/ES2/glext.h>

#include <OpenGLES/ES3/gl.h>
#include <OpenGLES/ES3/glext.h>

#define DNRColor    UIColor

// .............................................................................
#elif TARGET_OS_MAC
// .............................................................................

#define DNRPlatformMac


#include <OpenGL/gl.h>
#include <OpenGL/glu.h>


#define CGRectFromString NSRectFromString
#define CGPointFromString NSPointFromString


#define DNRColor    NSColor


// .............................................................................
#endif // #if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR



#endif /* Platform_h */
