//
//  DNRGLCache.h
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-05-03.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#ifndef __DNROpenGLESCache_h__
#define __DNROpenGLESCache_h__

#include "DNRBase.h"

// MAIN CONTEXT

// General
void viewPort(GLint x, GLint y, GLsizei width, GLsizei height);
void bindTexture2D(GLuint texture);
void bindVertexBufferObject(GLuint vbo);
void bindIndexBufferObject(GLuint ibo);
void bindVertexArrayObject(GLuint vao);
void clearColor4f(GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha);
void clearColor(Color4f newColor);

// Shader
void uniform1f(GLuint location, GLfloat scalar);
void uniform2fv(GLuint location, GLfloat* vector);
void uniform3fv(GLuint location, GLfloat* vector);
void uniform4fv(GLuint location, GLfloat* vector);
void useProgram(GLuint program);

// Framebuffer
void bindFramebuffer(GLuint framebuffer);
void bindRenderbuffer(GLuint renderbuffer);
void attachTexture2D(GLuint texture);

// BACKGROUND CONTEXT

// General
void viewPort_BG(GLint x, GLint y, GLsizei width, GLsizei height);
void bindTexture2D_BG(GLuint texture);
void bindVertexBufferObject_BG(GLuint vbo);
void bindIndexBufferObject_BG(GLuint ibo);
void bindVertexArrayObject_BG(GLuint vao);
void clearColor4f_BG(GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha);
void clearColor_BG(Color4f newColor);

// Shader
void uniform1f_BG(GLuint location, GLfloat scalar);
void uniform2fv_BG(GLuint location, GLfloat* vector);
void uniform3fv_BG(GLuint location, GLfloat* vector);
void uniform4fv_BG(GLuint location, GLfloat* vector);
void useProgram_BG(GLuint program);

// Framebuffer
void bindFramebuffer_BG(GLuint framebuffer);
void bindRenderbuffer_BG(GLuint renderbuffer);
void attachTexture2D_BG(GLuint texture);

#endif  // #defined (__DNROpenGLESCache_h__)
