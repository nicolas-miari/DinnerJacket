//
//  DNRGLCache.c
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-03-08.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#include "DNRBase.h"

#include <stdio.h>
#include "DNRGLCache.h"



#define OPENGL_CACHE_ENABLED

#define MaxPrograms                  20u
#define MaxVector2fPerProgram        20u
#define MaxVector3fPerProgram        20u
#define MaxVector4fPerProgram        20u
#define MaxScalarsPerProgram         20u



/**
 Caches some of the state of one OpenGL ES context. Calls that attempt to
 change state are issued only if they actually change the current value.
 When the call is meaningfull and the sate is changed, the new value is cached
 in order to evaluate further attempts to change.
 
 I do not know if this is a performance improvement or not, but at least it 
 keeps the OpenGL ES performance analyzer from warning about redundant state 
 changes.
 */
typedef struct tContextInfo {

    GLuint currentFramebuffer;
    
    GLuint currentRenderbuffer;
    
    GLuint currentVBO;
    GLuint currentIBO;
    GLuint currentVAO;
    GLuint currentTexture;
    GLuint currentBGTexture;
    
    GLuint currentProgram;
    
    Color4f currentColor;
    
    Color4f clearColor;
    
    GLuint currentTransTexture;
    
    GLint   viewPortX;
    GLint   viewPortY;
    GLsizei viewPortW;
    GLsizei viewPortH;
    
    GLfloat  scalars [MaxPrograms][MaxScalarsPerProgram];
    Vector2f vector2f[MaxPrograms][MaxVector2fPerProgram];
    Vector3f vector3f[MaxPrograms][MaxVector3fPerProgram];
    Vector4f vector4f[MaxPrograms][MaxVector4fPerProgram];
    
}ContextInfo;


static ContextInfo mainContextInfo       = {0};
static ContextInfo backgroundContextInfo = {0};


/*
void openGLCacheSetCurrentContext(GLuint context) {

    if (context == OpenGLCacheMainContext) {
        currentContextInfoPtr = &mainContextInfo;
    }
    else if(context == OpenGLCacheBackgroundContext){
        currentContextInfoPtr = &backgroundContextInfo;
    }
}
*/

#pragma mark - Main Context

// General
void viewPort(GLint x, GLint y, GLsizei width, GLsizei height) {

    ContextInfo* info = &mainContextInfo;
    
	if(x != info->viewPortX || y != info->viewPortY || width != info->viewPortW || height != info->viewPortH){
        // Set
        glViewport(x, y, width, height);
        
        // Cache
        info->viewPortX = x;
		info->viewPortY = y;
		info->viewPortW = width;
		info->viewPortH = height;
    }
}


void bindTexture2D(GLuint texture) {

    ContextInfo* info = &mainContextInfo;
    
    if(texture != info->currentTexture){
        // Set
        glBindTexture(GL_TEXTURE_2D, texture);
        
        // Cache
        info->currentTexture = texture;
    }
}


void bindVertexBufferObject(GLuint vbo) {

    ContextInfo* info = &mainContextInfo;
    
    if(vbo != info->currentVBO){
        // Set
        glBindBuffer(GL_ARRAY_BUFFER, vbo);
        
        // Cache
        info->currentVBO = vbo;
    }
}


void bindIndexBufferObject(GLuint ibo) {

    ContextInfo* info = &mainContextInfo;
    
    if(ibo != info->currentIBO){
        // Set
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo);
        
        // Cache
        info->currentIBO = ibo;
    }
}


void bindVertexArrayObject(GLuint vao) {

    ContextInfo* info = &mainContextInfo;
    
    if (vao != info->currentVAO) {
        // Set new value:
        //glBindVertexArrayOES(vao);
        glBindVertexArray(vao);
        
        // Cache it to keep in sync
        info->currentVAO = vao;
    }
}


void clearColor(Color4f newColor) {

    ContextInfo* info = &mainContextInfo;
    
    Color4f currentColor = (info->clearColor);
    
    if (currentColor.r != newColor.r || currentColor.g != newColor.g || currentColor.b != newColor.b || currentColor.a != newColor.a){
        // Set
        glClearColor(newColor.r, newColor.g, newColor.b, newColor.a);
        
        // Cache
        info->clearColor = newColor;
    }
}


void clearColor4f(GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha) {
    return clearColor(Color4fMake(red, green, blue, alpha));
}


void uniform1f(GLuint location, GLfloat scalar) {

    ContextInfo* info = &mainContextInfo;
    GLuint program = info->currentProgram;
    GLfloat s = info->scalars[program][location];
    
    if (s != scalar) {
        // Set
        glUniform1f(location, scalar);
        
        // Cache
        info->scalars[program][location] = scalar;
    }
}


void uniform2fv(GLuint location, GLfloat* vector) {

    ContextInfo* info = &mainContextInfo;
    GLuint program = info->currentProgram;
    Vector2f v = info->vector2f[program][location];
	
    if(vector[0] != v.x || vector[1] != v.y){
        
        // Set
        glUniform2fv(location, 1, vector);
        
        // Cache
        info->vector2f[program][location].x = vector[0];
		info->vector2f[program][location].y = vector[1];
    }
}


void uniform3fv(GLuint location, GLfloat* vector) {

    ContextInfo* info = &mainContextInfo;
    GLuint program = info->currentProgram;
    Vector3f v = info->vector3f[program][location];
	
    if(vector[0] != v.x || vector[1] != v.y || vector[2] != v.z){
        // Set
        glUniform3fv(location, 1, vector);
        
        // Cache
        info->vector3f[program][location].x = vector[0];
		info->vector3f[program][location].y = vector[1];
		info->vector3f[program][location].z = vector[2];
    }
}


void uniform4fv(GLuint location, GLfloat* vector) {

    ContextInfo* info = &mainContextInfo;
    GLuint program = info->currentProgram;
    Vector4f v = info->vector4f[program][location];
	
    if(vector[0] != v.x || vector[1] != v.y || vector[2] != v.z || vector[3] != v.w){
        // Set
        glUniform4fv(location, 1, vector);
        
        // Cache
        info->vector4f[program][location].x = vector[0];
		info->vector4f[program][location].y = vector[1];
		info->vector4f[program][location].z = vector[2];
		info->vector4f[program][location].w = vector[3];
    }
}


void useProgram(GLuint program) {

    ContextInfo* info = &mainContextInfo;
    
    if(program != info->currentProgram){
        // Set
        glUseProgram(program);
        
        // Cache
        info->currentProgram = program;
    }
}


// Framebuffer
void bindFramebuffer(GLuint framebuffer) {

    ContextInfo* info = &mainContextInfo;
    
    if(framebuffer != info->currentFramebuffer){
        // Set
        glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
        
        // Cache
        info->currentFramebuffer = framebuffer;
    }
}


void bindRenderbuffer(GLuint renderbuffer) {

    ContextInfo* info = &mainContextInfo;
    
    if(renderbuffer != info->currentRenderbuffer){
        // Set
        glBindRenderbuffer(GL_RENDERBUFFER, renderbuffer);
        
        // Cache
        info->currentRenderbuffer = renderbuffer;
    }
}


void attachTexture2D(GLuint texture) {

    ContextInfo* info = &mainContextInfo;
    
	if(texture != info->currentTransTexture){
        // Set
		glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texture, 0);
        
		// Cache
		info->currentTransTexture = texture;
	}
}


#pragma mark - Background Context

// General
void viewPort_BG(GLint x, GLint y, GLsizei width, GLsizei height) {

    ContextInfo* info = &backgroundContextInfo;
    
	if(x != info->viewPortX || y != info->viewPortY || width != info->viewPortW || height != info->viewPortH){
        // Set
        glViewport(x, y, width, height);
        
        // Cache
        info->viewPortX = x;
		info->viewPortY = y;
		info->viewPortW = width;
		info->viewPortH = height;
    }
}


void bindTexture2D_BG(GLuint texture) {

    ContextInfo* info = &backgroundContextInfo;
    
    if(texture != info->currentTexture){
        // Set
        glBindTexture(GL_TEXTURE_2D, texture);
        
        // Cache
        info->currentTexture = texture;
    }
    
}


void bindVertexBufferObject_BG(GLuint vbo) {

    ContextInfo* info = &backgroundContextInfo;
    
    if(vbo != info->currentVBO){
        // Set
        glBindBuffer(GL_ARRAY_BUFFER, vbo);
        
        // Cache
        info->currentVBO = vbo;
    }
}


void bindIndexBufferObject_BG(GLuint ibo) {

    ContextInfo* info = &backgroundContextInfo;
    
    if(ibo != info->currentIBO){
        // Set
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo);
        
        // Cache
        info->currentIBO = ibo;
    }
}


void bindVertexArrayObject_BG(GLuint vao) {

    ContextInfo* info = &backgroundContextInfo;
    
    if (vao != info->currentVAO) {
        // Set
        //glBindVertexArrayOES(vao);
        glBindVertexArray(vao);
        
        // Cache
        info->currentVAO = vao;
    }
    
}


void uniform1f_BG(GLuint location, GLfloat scalar) {

    ContextInfo* info = &backgroundContextInfo;
    GLuint program = info->currentProgram;
    GLfloat s = info->scalars[program][location];
    
    if (s != scalar) {
        // Set
        glUniform1f(location, scalar);
        
        // Cache
        info->scalars[program][location] = scalar;
    }
}


void uniform2fv_BG(GLuint location, GLfloat* vector) {

    ContextInfo* info = &backgroundContextInfo;
    GLuint program = info->currentProgram;
    Vector2f v = info->vector2f[program][location];
	
    if(vector[0] != v.x || vector[1] != v.y){
        
        // Set
        glUniform2fv(location, 1, vector);
        
        // Cache
        info->vector2f[program][location].x = vector[0];
		info->vector2f[program][location].y = vector[1];
    }
}


void uniform3fv_BG(GLuint location, GLfloat* vector) {

    ContextInfo* info = &backgroundContextInfo;
    GLuint program = info->currentProgram;
    Vector3f v = info->vector3f[program][location];
	
    if(vector[0] != v.x || vector[1] != v.y || vector[2] != v.z){
        // Set
        glUniform3fv(location, 1, vector);
        
        // Cache
        info->vector3f[program][location].x = vector[0];
		info->vector3f[program][location].y = vector[1];
		info->vector3f[program][location].z = vector[2];
    }
}


void uniform4fv_BG(GLuint location, GLfloat* vector) {

    ContextInfo* info = &backgroundContextInfo;
    GLuint program = info->currentProgram;
    Vector4f v = info->vector4f[program][location];
	
    if(vector[0] != v.x || vector[1] != v.y || vector[2] != v.z || vector[3] != v.w){
        // Set
        glUniform4fv(location, 1, vector);
        
        // Cache
        info->vector4f[program][location].x = vector[0];
		info->vector4f[program][location].y = vector[1];
		info->vector4f[program][location].z = vector[2];
		info->vector4f[program][location].w = vector[3];
    }
}


void useProgram_BG(GLuint program) {

    ContextInfo* info = &backgroundContextInfo;
    
    if(program != info->currentProgram){
        
        glUseProgram(program);
        info->currentProgram = program;
    }
}


// Framebuffer
void bindFramebuffer_BG(GLuint framebuffer) {

    ContextInfo* info = &backgroundContextInfo;
    
    if(framebuffer != info->currentFramebuffer){
        
        glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
        info->currentFramebuffer = framebuffer;
    }
}


void bindRenderbuffer_BG(GLuint renderbuffer) {

    ContextInfo* info = &backgroundContextInfo;
    
    if(renderbuffer != info->currentRenderbuffer){
        
        glBindRenderbuffer(GL_RENDERBUFFER, renderbuffer);
        info->currentRenderbuffer = renderbuffer;
    }
}


void attachTexture2D_BG(GLuint texture) {

    ContextInfo* info = &backgroundContextInfo;
    
	if(texture != info->currentTransTexture){
        // Set
		glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texture, 0);
        
		// Cache
		info->currentTransTexture = texture;
	}
}

