//
//  DNROpenGLES2Renderer.m
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-05-03.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import "DNRBase.h"
#if defined (DNRPlatformPhone)

#import "DNROpenGLES2Renderer.h"        // Own header

#import "DNROpenGLESView.h"             // Parent object

#import "DNRMatrix.h"                   // Math support

#import "DNRGLCache.h"            // OpenGL support
#import "DNROpenGLUtilities.h"

#import "DNRShaderManager.h"

#import "DNRGlobals.h"                  // Stride, etc.


@interface DNROpenGLES2Renderer ()

@property (nonatomic, unsafe_unretained, readwrite) DNROpenGLESView* view;
@property (nonatomic, readwrite) EAGLContext* context;
@property (nonatomic, readwrite) EAGLContext* backgroundContext;
@property (nonatomic, readwrite) GLint backingWidth;
@property (nonatomic, readwrite) GLint backingHeight;
@property (nonatomic, readwrite) GLuint vao;
@property (nonatomic, readwrite) GLuint vbo;
@property (nonatomic, readwrite) GLuint ibo;
@property (nonatomic, readwrite) GLuint currentFramebuffer;
@property (nonatomic, readwrite) GLuint mainFramebuffer;
@property (nonatomic, readwrite) GLuint mainColorbuffer;
@property (nonatomic, readwrite) GLuint depthBuffer;
@property (nonatomic, readwrite) BOOL usingStencilBuffer;

@property (nonatomic, readwrite) GLuint transFramebuffer;
@property (nonatomic, readwrite) GLuint transTexture1;
@property (nonatomic, readwrite) GLuint transTexture2;
@property (nonatomic, readwrite) GLuint transDepthBuffer;
@property (nonatomic, readwrite) GLuint spriteProgram;

@property (nonatomic, readwrite) GLint samplerLocation;
@property (nonatomic, readwrite) GLint modelviewLocation;
@property (nonatomic, readwrite) GLint projectionLocation;
@property (nonatomic, readwrite) GLint colorLocation;

@property (nonatomic, readwrite) GLint positionLocation;
@property (nonatomic, readwrite) GLint texCoordLocation;

@end

// .............................................................................


@implementation DNROpenGLES2Renderer {

    GLfloat			_translateMatrix[16];
	GLfloat			_scaleMatrix[16];
}

// Properties declared in a protocol won't be auto-synthesized:
@synthesize backgroundClearColor = _backgroundClearColor;
@synthesize sceneClearColor      = _sceneClearColor;

@synthesize zoomScale;
@synthesize scrollOffset;

#pragma mark - DNROpenGLESRenderer Protocol Methods (All iOS Renderers)


- (id) initWithView:(DNROpenGLESView *)view stencilBufferBits:(NSUInteger) stencilBits {

    if ((self = [super init])) {
        
        // Keep a reference to the view, so we
        //  can -resizeFromLayer later.
        _view = view;
        
        _usingStencilBuffer = (stencilBits != 0);
        
        
        // 0. Create OpenGL ES contexts
        
        _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
        
        if (!_context) {
            return (self = nil);
        }
        
        _backgroundContext = [[EAGLContext alloc] initWithAPI:[_context API]
                                                   sharegroup:[_context sharegroup]];
        
        // (TODO: Add support for OpenGL ES 3.0, and fall back to ES 2.0)
        
        // 1. Create drawables
        if ([self createFramebuffers] == NO) {
            return (self = nil);
        }
        
        // 2. Configure shaders
        if ([[DNRShaderManager defaultManager] initializeDefaultPrograms] == NO) {
            return ((self = nil));
        }
        [self initializeSpriteProgram];
        
        
        // 3. Create geometry
        if ([self createGeometry] == NO) {
            return ((self = nil));
        }
        
        // 4. Set default OpenGL State
        [self restoreDefaultOpenGLStates];
        
        // 5. Setup modelview matrix
        [self updateModelviewMatrix];
    }
    
    return self;
}


- (BOOL) resizeFromLayer:(CAEAGLLayer *)layer {

    [EAGLContext setCurrentContext:_context];
    
    
    // .. ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ..
    // [ A ] On-screen drawables
    
    // 1. Resize color buffer
    
    bindFramebuffer(_mainFramebuffer);      // Needed?
    
    bindRenderbuffer(_mainColorbuffer);
    
    // Adjust size to match view's layer:
    [_context renderbufferStorage:GL_RENDERBUFFER
                     fromDrawable:(CAEAGLLayer *)[_view layer]];
    
    // Query the new size:
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH,  &_backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
    
    
    // 2. Resize the depth buffer too
    
    bindRenderbuffer(_depthBuffer);
    
    if (_usingStencilBuffer) {
        // Depth and stencil
        
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8_OES, _backingWidth, _backingHeight);
    }
    else{
        // Depth alone
        
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24_OES, _backingWidth, _backingHeight);
    }
    
    // Finally, validate the set:
    
    GLenum framebufferStatus = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    
    if ( framebufferStatus != GL_FRAMEBUFFER_COMPLETE) {
        // Something went wrong!
        
        DLog(@"-[GPES2Renderer resizeFromLayer:]: Failed to make complete framebuffer object: %@",
             [self stringFromFramebufferStauts:glCheckFramebufferStatus(GL_FRAMEBUFFER)]);
        
        return NO;
    }
    
    
    // .. ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ..
    // [ B ] Off-screen (render-to-texture) drawables
    
    bindFramebuffer(_transFramebuffer);        // Needed?
    
    
    // 1. Resize the depth buffer
    
    bindRenderbuffer(_transDepthBuffer);
    
    if (_usingStencilBuffer) {
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8_OES, _backingWidth, _backingHeight);
    }
    else{
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24_OES, _backingWidth, _backingHeight);
    }
    
    
    // 2. Resize the off-screen textures
    
    GLuint* textureIDPointers[2] = { &_transTexture1, &_transTexture2 };
    
    for (NSUInteger i = 0; i < 2; i++) {
        
        GLuint* textureIDPointer = textureIDPointers[i];
        
        bindTexture2D(*textureIDPointer);
        
        // Configure for pixel-aligned use:
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        // Allocate storage:
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _backingWidth, _backingHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
        
        
        // Attach:
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, *textureIDPointer, 0);
        
        
        // Validate:
        framebufferStatus = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        
        if ( framebufferStatus != GL_FRAMEBUFFER_COMPLETE) {
            // Something went wrong!
            
            DLog(@"-[GPES2Renderer resizeFromLayer:]: Failed to make complete framebuffer object: %@",
                 [self stringFromFramebufferStauts:glCheckFramebufferStatus(GL_FRAMEBUFFER)]);
            
            return NO;
        }
    }
    
    
    bindFramebuffer(_mainFramebuffer);
    bindRenderbuffer(_mainColorbuffer);     // Needed?
    
    
    // 3. Matrix and shader setup
    
    [self updateModelviewMatrix];
    
    
    // 4. Viewport
    
    glViewport(0, 0, _backingWidth, _backingHeight);
    
    
    //DLog(@"-[GPES2Renderer resizeFromLayer:] - SUCEEDED!");

    
    // .. ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ..
    // Done!
    
    return YES;
}


#pragma mark - DNRRenderer Protocol Methods (All Platform Renderers)


- (void) beginFrame {

    bindFramebuffer(_mainFramebuffer);
    
    _currentFramebuffer = _mainFramebuffer;
    
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
}


- (void) endFrame {

    static GLenum attachments[] = { GL_DEPTH_ATTACHMENT };
    
    // Discard depth buffer contents:
    glDiscardFramebufferEXT(GL_FRAMEBUFFER, 1, attachments);
    
    // Present color buffer to Core Animation:
    bindRenderbuffer(_mainColorbuffer);
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}


- (void) initializeSequentialFade {

    // Bind the Transition framebuffer:
    bindFramebuffer(_transFramebuffer);
    _currentFramebuffer = _transFramebuffer;
    
    // Attach texture #1 to its color attachment:
    attachTexture2D(_transTexture1);
}


- (void) beginSequentialFadeFrame {
    /*
     Called at the beginning of each frame of a fade in/fade out
	 transition. Between this call and the call to
     -blendSequentialFadePassWithOpacity: the scene geometry is rendered.
	 Setup Environment for Rendering the (only) Scene into Texture # 1
     */
    
    // 0. Bind the Transition framebuffer:
    bindFramebuffer(_transFramebuffer);
    _currentFramebuffer = _transFramebuffer;
    
    
    // 1. Clear the screen:
    clearColor(_sceneClearColor);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
    
    // (must clear depth buffer too, otherwise 3D objects won't render properly
    //  during transitions)
    
    // (all geometry rendering follows...)
}


- (void) blendSequentialFadePassWithOpacity:(CGFloat) opacity {

    // Modulate Rendered Scene into the Screen, at the Appropriate Opacity
    
    glDisable(GL_DEPTH_TEST);
    
    static GLfloat color4fv[4] = { 1.0f, 1.0f, 1.0f, 1.0f };
    
    
    // Bind main framebuffer: (renders to screen)
    bindFramebuffer(_mainFramebuffer);
    _currentFramebuffer = _mainFramebuffer;
    
    
    // Clear the screen:
    clearColor(_backgroundClearColor);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
    
    
    // Bind shaders
    useProgram(_spriteProgram);

    
    // Upload scale matrix to shader:
    glUniformMatrix4fv(_modelviewLocation, 1, 0, _scaleMatrix);
    // (alternatively, we could create the quad to screen size)
    
    
    // Upload color (blend opacity) to shader:
    
    color4fv[0] = opacity;
    color4fv[1] = opacity;
    color4fv[2] = opacity;
    color4fv[3] = opacity;
    
    uniform4fv(_colorLocation, color4fv);
    
    // Bind scene texture
    bindTexture2D(_transTexture1);
    
    // Bind quad geometry
    bindVertexArrayObject(_vao);
    
    // Draw
    glDrawElements(GL_TRIANGLE_STRIP, 4, GL_UNSIGNED_SHORT, 0);
    
    
    
    // .. ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ..
	// Discard Depth Buffer
    
	static GLenum attachments[] = { GL_DEPTH_ATTACHMENT };
	glDiscardFramebufferEXT(GL_FRAMEBUFFER, 1, attachments);
	
    
    // .. ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ..
	// Present RESOLVE Colorbuffer to CoreAnimation
	
    bindRenderbuffer(_mainColorbuffer);
	[_context presentRenderbuffer:GL_RENDERBUFFER];
    
    glEnable(GL_DEPTH_TEST);
}


- (void) beginCrossDissolveFramePass1 {

    // Bind the Transition framebuffer:
    bindFramebuffer(_transFramebuffer);
    _currentFramebuffer = _transFramebuffer;
    
    // Attach texture #1 to its color attachment:
    attachTexture2D(_transTexture1);
    
    // Clear the screen:
    
    clearColor(_sceneClearColor);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);

    // (rendering of FIRST scene follows...)
}


- (void) beginCrossDissolveFramePass2 {

    // Bind the Transition framebuffer:
    bindFramebuffer(_transFramebuffer);
    _currentFramebuffer = _transFramebuffer;

    
    // Attach texture #2 to its color attachment:
    attachTexture2D(_transTexture2);
    
    // Clear the screen:
    clearColor(_sceneClearColor);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
    
    // (rendering of SECOND scene follows...)
}


- (void) blendCrossDissolvePassesWithProgress:(CGFloat) progress {

    // Disable depth culling. Both quads should be drawn!
    glDisable(GL_DEPTH_TEST);
    
    static GLfloat color4fv[4] = { 1.0f, 1.0f, 1.0f, 1.0f };
    
    
    // Rendering to the screen:
    bindFramebuffer(_mainFramebuffer);
    _currentFramebuffer = _mainFramebuffer;
    

    clearColor(_backgroundClearColor);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
    
    useProgram(_spriteProgram);
    glUniformMatrix4fv(_modelviewLocation, 1, 0, _scaleMatrix);
    bindVertexArrayObject(_vao);
    
    // Scene 1 Fades OUT:
    
    GLfloat opacity = 1.0f - progress;
    color4fv[0] = opacity;
    color4fv[1] = opacity;
    color4fv[2] = opacity;
    color4fv[3] = opacity;
    
    uniform4fv(_colorLocation, color4fv);
    bindTexture2D(_transTexture1);
    glDrawElements(GL_TRIANGLE_STRIP, 4, GL_UNSIGNED_SHORT, 0);
    
    // ---
    
    // Scene 1 Fades IN:
    color4fv[0] = progress;
    color4fv[1] = progress;
    color4fv[2] = progress;
    color4fv[3] = progress;
    
    uniform4fv(_colorLocation, color4fv);
    bindTexture2D(_transTexture2);
    glDrawElements(GL_TRIANGLE_STRIP, 4, GL_UNSIGNED_SHORT, 0);
    

    // Cleanup:
    static GLenum attachments[] = { GL_DEPTH_ATTACHMENT };
    glDiscardFramebufferEXT(GL_FRAMEBUFFER, 1, attachments);
    
    // Dsiplay composition:
    bindRenderbuffer(_mainColorbuffer);
    [_context presentRenderbuffer:GL_RENDERBUFFER];
    
    glEnable(GL_DEPTH_TEST);
}


#pragma mark - Internal Operation


- (NSString *)stringFromFramebufferStauts:(NSUInteger) status {

    switch (status) {
        case GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT:
            return @"GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT";
            break;
            
        case GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS:
            return @"GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS";
            break;
            
        case GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT:
            return @"GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT";
            break;
            
        case GL_FRAMEBUFFER_UNSUPPORTED:
            return @"GL_FRAMEBUFFER_UNSUPPORTED";
            break;
            
        default:
            return [NSString stringWithFormat:@"Unknown (Code: %lu)", (unsigned long)status];
            break;
    }
}


- (BOOL) createFramebuffers {

    [EAGLContext setCurrentContext:_context];
    
    
    // .. ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ..
    // [ A ] On-screen
    
    
    // 1. Framebuffer
    
    glGenFramebuffers(1, &_mainFramebuffer);
    bindFramebuffer(_mainFramebuffer);
    //checkOpenGLError();
    
    // 2. Color buffer
    
    glGenRenderbuffers(1, &_mainColorbuffer);
    bindRenderbuffer(_mainColorbuffer);
    //checkOpenGLError();
    
    // Adjust size to view's layer:
    
    CAEAGLLayer* layer = (CAEAGLLayer*)[_view layer];
    
    if (![_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer]) {
        // something went horribly wrong
        
        DLog(@"-[GPES2Renderer createFramebuffers]: Failed to obtain renderbuffer storage from layer!");
        
        return NO;
    }
    
    //checkOpenGLError();
    
    // Query new size:
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH,  &_backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
    //checkOpenGLError();
    
    // Attach to color:
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _mainColorbuffer);
    //checkOpenGLError();
    
    
    // 3. Depth buffer
    
    glGenRenderbuffers(1, &_depthBuffer);
    bindRenderbuffer(_depthBuffer);
    //checkOpenGLError();
    
    if (_usingStencilBuffer) {
        // Depth + Stencil
        
        // Allocate storage:
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8_OES, _backingWidth, _backingHeight);
        //checkOpenGLError();
        
        // Attach to depth:
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthBuffer);
        //checkOpenGLError();
        
        // Attach to stencil:
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_STENCIL_ATTACHMENT, GL_RENDERBUFFER, _depthBuffer);
        //checkOpenGLError();
    }
    else{
        // Depth only
        
        // Allocate storage:
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24_OES, _backingWidth, _backingHeight);
        //checkOpenGLError();
        
        // Attachto depth:
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthBuffer);
        //checkOpenGLError();
    }
    
    
    // 4. Validate the set:
    
    GLenum framebufferStatus = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    
    if (framebufferStatus != GL_FRAMEBUFFER_COMPLETE) {
        // Something went wrong!
        
        DLog(@"-[GPES2Renderer createFramebuffers]: Failed to make complete framebuffer object: %@",
             [self stringFromFramebufferStauts:framebufferStatus]);
        
        return NO;
    }
    
    
    // .. ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ..
    // [ B ] Off-screen (Render-to-texture)
    
    
    // 1. Framebuffer
    
    glGenFramebuffers(1, &_transFramebuffer);
    bindFramebuffer(_transFramebuffer);
    //checkOpenGLError();
    
    
    // 2. Depth buffer
    
    glGenRenderbuffers(1, &_transDepthBuffer);
    bindRenderbuffer(_transDepthBuffer);
    //checkOpenGLError();
    
    if (_usingStencilBuffer) {
        // Allocate storage:
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8_OES, _backingWidth, _backingHeight);
        //checkOpenGLError();
        
        // Attach to depth:
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _transDepthBuffer);
        //checkOpenGLError();
        
        // Attach to stencil:
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_STENCIL_ATTACHMENT, GL_RENDERBUFFER, _transDepthBuffer);
        //checkOpenGLError();
    }
    else{
        // Allocate storage
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24_OES, _backingWidth, _backingHeight);
        //checkOpenGLError();
        
        // Attach to depth:
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _transDepthBuffer);
        //checkOpenGLError();
    }
    
    
    
    // 3. Textures (color buffers)
    
    GLuint* texPtrs[2] = {&_transTexture1, &_transTexture2};
    
    for (NSUInteger i=0; i < 2; i++) {
        
        GLuint* texPtr = texPtrs[i];
        
        glGenTextures(1, texPtr);
        
        bindTexture2D(*texPtr);
        
        // Configure for pixel-aligned use:
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        // Allocate storage:
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _backingWidth, _backingHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
        
        
        // Attach:
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, *texPtr, 0);
        
        framebufferStatus = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        
        // Validate:
        
        if ( framebufferStatus != GL_FRAMEBUFFER_COMPLETE) {
            // Something went wrong!
            
            DLog(@"-[GPES2Renderer createFramebuffers]: Failed to make complete framebuffer object: %@",
                 [self stringFromFramebufferStauts:framebufferStatus]);
            
            return NO;
        }
    }
    
    // .. ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ..
    // Final State:
    
    bindFramebuffer(_mainFramebuffer);
    bindRenderbuffer(_mainColorbuffer);
    bindTexture2D(0);
    
    //checkOpenGLError();
    
    // Nothing went wrong! Yay!
    
    //DLog(@"-[GPES2Renderer createFramebuffers] Succeeded.");
    
    return YES;
}


- (void) destroyFramebuffers {

    if (_mainFramebuffer) {
        glDeleteFramebuffers(1, &_mainFramebuffer);
        _mainFramebuffer = 0;
    }
    
    if (_mainColorbuffer) {
        glDeleteRenderbuffers(1, &_mainColorbuffer);
        _mainColorbuffer = 0;
    }
    
    if (_depthBuffer) {
        glDeleteRenderbuffers(1, &_depthBuffer);
    }
    
    if (_transFramebuffer) {
        glDeleteFramebuffers(1, &_transFramebuffer);
        _transFramebuffer = 0;
    }
    
    if (_transTexture1) {
        glDeleteTextures(1, &_transTexture1);
        _transTexture1 = 0;
    }
    
    if (_transTexture2) {
        glDeleteTextures(1, &_transTexture2);
        _transTexture2 = 0;
    }
    
    if (_transDepthBuffer) {
        glDeleteRenderbuffers(1, &_transDepthBuffer);
        _transDepthBuffer = 0;
    }
}


- (BOOL) createGeometry {

    CGFloat s0 = 0.0;
    CGFloat s1 = 1.0;
    CGFloat t0 = 0.0;
    CGFloat t1 = 1.0;
    
    VertexData2D vertexData[4];
    
    // Bottom right
    vertexData[0].position.x   = +0.5f;
    vertexData[0].position.y   = -0.5f;
    vertexData[0].texCoords.s  = s1;
    vertexData[0].texCoords.t  = t1;
    
    // Top right
    vertexData[1].position.x   = +0.5f;
    vertexData[1].position.y   = +0.5f;
    vertexData[1].texCoords.s  = s1;
    vertexData[1].texCoords.t  = t0;
    
    // Bottom left
    vertexData[2].position.x   = -0.5f;
    vertexData[2].position.y   = -0.5f;
    vertexData[2].texCoords.s  = s0;
    vertexData[2].texCoords.t  = t1;
    
    // Top left
    vertexData[3].position.x   = -0.5f;
    vertexData[3].position.y   = +0.5f;
    vertexData[3].texCoords.s  = s0;
    vertexData[3].texCoords.t  = t0;
    
    
    GLushort indices[4] = {0, 1, 2, 3};
    
    
    // .. ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ..
    // VAO VERSION
    
    glGenVertexArrays(1, &_vao);
    bindVertexArrayObject(_vao);
    
    
    glGenBuffers(1, &_vbo);
    bindVertexBufferObject(_vbo);
    
    glBufferData(GL_ARRAY_BUFFER,
                 4*sizeof(VertexData2D),
                 &vertexData[0],
                 GL_STATIC_DRAW);
    
    
    glGenBuffers(1, &_ibo);
    bindIndexBufferObject(_ibo);
    
    glBufferData(GL_ELEMENT_ARRAY_BUFFER,
                 4*sizeof(GLushort),
                 &indices[0],
                 GL_STATIC_DRAW);
    
    
    glEnableVertexAttribArray(_positionLocation);
    glEnableVertexAttribArray(_texCoordLocation);

    glVertexAttribPointer(_positionLocation, 2, GL_FLOAT, GL_FALSE, stride2D, positionOffset2D);
    glVertexAttribPointer(_texCoordLocation, 2, GL_FLOAT, GL_FALSE, stride2D, textureOffset2D);
    
    
    // At this point the VAO is set up with two vertex attributes
    // referencing the same buffer object, and another buffer object
    // as source for index data. We can now unbind the VAO, go do
    // something else, and bind it again later when we want to render
    // with it.
    bindVertexArrayObject(0);
    
    glDisableVertexAttribArray(_positionLocation);
    glDisableVertexAttribArray(_texCoordLocation);
    
    bindIndexBufferObject(0);
    bindVertexBufferObject(0);
    
    // VAO VERSION
    // .. ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ..
    
    
    return YES;
}


- (void) restoreDefaultOpenGLStates {

    // Depth
    glEnable(GL_DEPTH_TEST);
    
    // Blending
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    // (OpenGL default blend function is: GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    
    
    // Scissor
    glDisable(GL_SCISSOR_TEST);
    
    
    // Clear Color
    clearColor(_backgroundClearColor);
    
    // Viewport
    viewPort(0.0f, 0.0, _backingWidth, _backingHeight);
}


- (void) initializeSpriteProgram {

    // 0. Grab Handle
    DNRShaderManager* shaderManager = [DNRShaderManager defaultManager];
    
    _spriteProgram = [shaderManager spriteProgram];
    
    useProgram(_spriteProgram);
    
    
    
    // 1. Cache Access Points
    
	_samplerLocation = glGetUniformLocation(_spriteProgram, "Sampler");
	glUniform1i(_samplerLocation, 0);
	
	_modelviewLocation	 = glGetUniformLocation(_spriteProgram, "Modelview");
	_projectionLocation  = glGetUniformLocation(_spriteProgram, "Projection");
	_colorLocation       = glGetUniformLocation(_spriteProgram, "Color");
	
	_positionLocation  = glGetAttribLocation(_spriteProgram, "Position");
	_texCoordLocation  = glGetAttribLocation(_spriteProgram, "TextureCoord");
    
    
    // Set Projection Matrix (once)
    
    setOrthographicProjection(_spriteProgram,
                              glGetUniformLocation(_spriteProgram, "Projection"),
                              -0.5*(_backingWidth),
                              +0.5*(_backingWidth),
                              -0.5*(_backingHeight),
                              +0.5*(_backingHeight),
                              -1.0,
                              +1.0);
    
    
    // Do the same for Flat program
    
    GLuint flatProgram = [shaderManager flatProgram];
    
    useProgram(flatProgram);
    
    setOrthographicProjection(flatProgram,
                              glGetUniformLocation(_spriteProgram, "Projection"),
                              -0.5*(_backingWidth),
                              +0.5*(_backingWidth),
                              -0.5*(_backingHeight),
                              +0.5*(_backingHeight),
                              -1.0,
                              +1.0);
    
    // Alpha test program
    GLuint alphaProgram = [shaderManager spriteProgramWithAlphaTest];
    
    useProgram(alphaProgram);
    
    setOrthographicProjection(alphaProgram,
                              glGetUniformLocation(_spriteProgram, "Projection"),
                              -0.5*(_backingWidth),
                              +0.5*(_backingWidth),
                              -0.5*(_backingHeight),
                              +0.5*(_backingHeight),
                              -1.0,
                              +1.0);
    
    useProgram(0);
}


- (void) updateModelviewMatrix {

    // Called on initialization and screen resize.
    // Configures the modelview matrix so that when applied to the unit quad, it
    // fills the entire screen
    
    mat4f_LoadIdentity(_scaleMatrix);
    
    _scaleMatrix[ 0] = _backingWidth;		// X Scale
	_scaleMatrix[ 5] = -_backingHeight;     // Y Scale [*]
    
    
    // [*] Y scale is reversed because in bitmap coords +Y is down, but in
    //  OpenGL +Y is up)
}

@end


#endif // #if defined (DNRPlatformPhone)
