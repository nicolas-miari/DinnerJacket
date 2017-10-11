//
//  DNROpenGLUtilities.h
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-03-08.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#ifndef __DNROpenGLUtilities_h__
#define __DNROpenGLUtilities_h__

#include "DNRBase.h"



/** 
 Calls glGetError and prints a human readable message to stdout.
 */
void checkOpenGLError(void);


/** 
 Configures the passed program's Projection matrix to the specified parameters.
 */
void setOrthographicProjection(GLuint program,
                               GLuint projectionUniformLocation,
                               GLfloat xMin,
                               GLfloat xMax,
                               GLfloat yMin,
                               GLfloat yMax,
                               GLfloat zMin,
                               GLfloat zMax);



#endif  // #defined (__DNROpenGLUtilities_h__)
