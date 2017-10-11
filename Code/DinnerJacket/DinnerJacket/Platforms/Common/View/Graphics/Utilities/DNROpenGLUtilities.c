//
//  DNROpenGLUtilities.c
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-03-08.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#include <stdio.h>

#include "DNROpenGLUtilities.h"


void checkOpenGLError() {

#ifdef DEBUG
	GLuint error = glGetError();
    
	switch (error) {
		case GL_INVALID_ENUM:
			printf("GL_INVALID_ENUM\n");
			break;
		case GL_INVALID_OPERATION:
			printf("GL_INVALID_OPERATION\n");
			break;
            
        case GL_INVALID_FRAMEBUFFER_OPERATION:
            printf("GL_INVALID_FRAMEBUFFER_OPERATION\n");
			break;
            
		case GL_INVALID_VALUE:
			printf("GL_INVALID_VALUE\n");
			break;
			
		case GL_OUT_OF_MEMORY:
			printf("GL_OUT_OF_MEMORY\n");
			break;
            
        case GL_NO_ERROR:
            break;
            
		default:
            printf("Unknown Error: %u", error);
			break;
	}
#endif
    
}


void setOrthographicProjection(GLuint program,
                               GLuint projectionUniformLocation,
                               GLfloat xMin,
                               GLfloat xMax,
                               GLfloat yMin,
                               GLfloat yMax,
                               GLfloat zMin,
                               GLfloat zMax) {

    /*
     WTF?
     https://en.wikipedia.org/wiki/Orthographic_projection
     */
    
    float a = 2.0f / (xMax - xMin);
    float b = 2.0f / (yMax - yMin);
    float c = -2.0f / (zMax - zMin);
    
    float d = - (xMax + xMin)/(xMax - xMin);
    float e = - (yMax + yMin)/(yMax - yMin);
    float f = - (zMax + zMin)/(zMax - zMin);
    
    float ortho[16] = {
           a,  0.0f,  0.0f,     d,
        0.0f,     b,  0.0f,     e,
        0.0f,  0.0f,     c,     f,
        0.0f,  0.0f,  0.0f,  1.0f
    };
    
    glUniformMatrix4fv(projectionUniformLocation, 1, 0, &ortho[0]);
    
    /*
    float a = 1.0f / ((xMax - xMin)/2.0f);
	float b = 1.0f / ((yMax - yMin)/2.0f);
    
	float ortho[16] = {
        a,     0.0f,  0.0f,  0.0f,
		0.0f,     b,  0.0f,  0.0f,
		0.0f,  0.0f,  zMin,  0.0f,
		0.0,   0.0f,  0.0f,  zMax
	};
	
	glUniformMatrix4fv(projectionUniformLocation, 1, 0, &ortho[0]);
     */
}

