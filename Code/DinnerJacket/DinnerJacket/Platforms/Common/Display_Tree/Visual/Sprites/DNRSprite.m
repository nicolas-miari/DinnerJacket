//
//  DNRSprite.m
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-05-02.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import "DNRSprite.h"

#import "DNRTextureAtlas.h"             // Resource managers
#import "DNRShaderManager.h"

#import "DNRGLCache.h"            // Graphics support

#import "DNRMatrix.h"                   // Math support

#import "DNRGlobals.h"                  // scaleFactor

#import "DNRControl.h"

#import "DNRSpriteFrame.h"              // Multi-frame animation

#import "DNRFrameAnimationSequence.h"



NSString* const DNRSpriteBecameReadyNotification = @"SpriteBecameReady";


// 1. Shader program handle (shared among all instances)
static GLuint program                      = 0u;   // 0u flags 'not set' for GLint


// Shader attribute/uniform locations (shared among all instances)
static GLint positionLocation              = -1;   // -1 flags 'not set' for GLuint
static GLint texCoordLocation              = -1;
static GLint zLocation                     = -1;
static GLint colorLocation                 = -1;
static GLint samplerLocation               = -1;
static GLint modelviewLocation             = -1;


// 2. Alpha test program
//static GLuint alphaTestProgram             = 0u;

//// Shader attribute/uniform locations (shared among all instances)
//static GLint alphaTestPositionLocation     = -1;
//static GLint alphaTestTexCoordLocation     = -1;
//static GLint alphaTestZLocation            = -1;
//static GLint alphaTestColorLocation        = -1;
//static GLint alphaTestSamplerLocation      = -1;
//static GLint alphaTestModelviewLocation    = -1;


// 3. Flat shading program
static GLuint flatProgram                  = 0u;

// Shader attribute/uniform locations (shared among all instances)
static GLint flatPositionLocation          = -1;
static GLint flatZLocation                 = -1;
static GLint flatColorLocation             = -1;
static GLint flatModelviewLocation         = -1;


// Vertex array object for flat sprites (shared among all instances)
static GLuint flatVAO                      = 0u;


// -----------------------------------------------------------------------------

#pragma mark - PUBLIC BASE CLASS (INTERNAL INTERFACE)

@interface DNRSprite()

/// Source texture atlas. Value is nil for solid (non-textured) sprites.
/// Reference is kept around beyond initialization time so we can decrease the
/// atlas' use count on sprite deallocation (unreferenced atlases can be purged)
@property (nonatomic, unsafe_unretained) DNRTextureAtlas* textureAtlas;


/// Texture to bind before rendering (OpenGL name. Wrapping DNRTexture object
/// is reference-held by the atlas itself. When no existing atlas references a
/// given texture, that means it can be safely purged from memory and the OpenGL
/// texture data is purged as well.)
@property (nonatomic, readwrite) GLuint textureName;


/// Vertex buffer object for rendering quad. It encapsulates a custom triangle
/// mesh containing vertices mapped to each subimage and sized accordingly, and
/// enables the shader client states.
@property (nonatomic, readwrite) GLuint vao;


/// Index buffer object for rendering quad.
@property (nonatomic, readwrite) GLuint ibo;


/// Whether it can be rendered with GL_BLEND disabled or not (opaque geometry is
/// rendered first, then al semitransparent geometry is rendered back to forth).
@property (nonatomic, readwrite) BOOL opaque;


/// Name of the subimage entries in the texture atlas' database
@property (nonatomic, readwrite, copy) NSArray *subimageNames;


/// Color for blending on top of original color (solid) or texture (textured).
//@property (nonatomic, readwrite) Color4f tintColorComponents;


///
@property (nonatomic, readwrite) CGFloat complementaryColorBlendFactor;


/// The original size of the sprite, in points, when scale is (1.0, 1.0).
/// (Applies only to textured sprites, in which it is the native size of the
///  subtexture. Solid sprites have a "native size" of 1x1)
@property (nonatomic, readwrite) CGSize nativeSize;


/// The original color of the sprite, if solid. Textured sprites are assumed to
/// have a 'native color' of white, and only _tintColor is used.
@property (nonatomic, readwrite) Color4f nativeColor;



/// Index of the currently displayed subimage name within the subimaNames array.
@property (nonatomic, readwrite) NSUInteger currentSubimageIndex;

/// Index of the currently displayed animation frame
@property (nonatomic, readwrite) NSUInteger currentFrameIndex;

/// Duration of the currently displayed animation frame.
@property (nonatomic, readwrite) CFTimeInterval currentFrameDuration;

/// For how long the current animation frame has been displayed.
@property (nonatomic, readwrite) CFTimeInterval currentFrameEllapsedTime;

/// Animation frames from the current sequence.
@property (nonatomic, readwrite) NSArray* animationFrames;

/// State flag.
@property (nonatomic, readwrite) BOOL animating;

/// Total repeat count of the current animation sequence.
@property (nonatomic, readwrite) NSUInteger maxLoopCount;

/// Repeats left in the current animation sequence.
@property (nonatomic, readwrite) NSUInteger loopsLeft;

///
@property (nonatomic, readwrite) void (^animationCompletionHandler)(void);


@end


// .............................................................................

@implementation DNRSprite {

    // Set to _tintcolor and modulated by alpha, before passing to shader.
    GLfloat     _renderColor4f[4];
    
    
    // Modelview matrix
    GLfloat     _modelview4fv[16];
    
    
    // Applied scale
    GLfloat     _scale3f[3];
    
    
    // Used for culling
    GLfloat     _boundsX0;
    GLfloat     _boundsX1;
    GLfloat     _boundsY0;
    GLfloat     _boundsY1;
    
    
    // .........................................................................
    // FRAME ANIMATION
    

}


+ (void) initialize {

    if(self == [DNRSprite class]){
        
        // . .. . .. . .. . .. . .. . .. . .. . .. . .. . .. . .. . .. . .. . ..
        // TEXURED
        
        if (program == 0) {
            
            // Cache program
            program = [[DNRShaderManager defaultManager] spriteProgram];
            
            //DLog(@"PROGRAM: %d", program);
            
            // Cache attributes
            positionLocation  = glGetAttribLocation (program, "Position"    );
            texCoordLocation  = glGetAttribLocation (program, "TextureCoord");
            
            // Cache uniforms
            colorLocation     = glGetUniformLocation(program, "Color"    );
            samplerLocation   = glGetUniformLocation(program, "Sampler"  );
            modelviewLocation = glGetUniformLocation(program, "Modelview");
            zLocation         = glGetUniformLocation(program, "Z"        );
        }
        
        if (flatProgram == 0) {
            
            // Cache program
            flatProgram = [[DNRShaderManager defaultManager] flatProgram];
            
            // Cache attributes
            flatPositionLocation  = glGetAttribLocation (flatProgram, "Position" );
            
            // Cache uniforms
            flatColorLocation     = glGetUniformLocation(flatProgram, "Color"    );
            flatModelviewLocation = glGetUniformLocation(flatProgram, "Modelview");
            flatZLocation         = glGetUniformLocation(flatProgram, "Z"        );
        }
        
        
        // . .. . .. . .. . .. . .. . .. . .. . .. . .. . .. . .. . .. . .. . ..
        // SOLID
        
        if (flatVAO == 0) {
            
            // Initialize the vertex array object shared by all solid sprites
            // (done only for the lifetime of the process).
            
            // Origin-centered unit quad:
            VertexData2D* vertices = (VertexData2D *)calloc(sizeof(VertexData2D), 4);
            
            vertices[0].position.x  = +0.5f;
            vertices[0].position.y  = -0.5f;
            
            vertices[1].position.x  = +0.5f;
            vertices[1].position.y  = +0.5f;
            
            vertices[2].position.x  = -0.5f;
            vertices[2].position.y  = -0.5f;
            
            vertices[3].position.x  = -0.5f;
            vertices[3].position.y  = +0.5f;
            
            
            flatProgram = [[DNRShaderManager defaultManager] flatProgram];
            useProgram(flatProgram);
            
            GLint flatPositionLocation = glGetAttribLocation(flatProgram, "Position");
            
            GLuint vbo = 0;
            
            
            glGenVertexArrays(1, &flatVAO);
            bindVertexArrayObject(flatVAO);
            
            glGenBuffers(1, &vbo);
            bindVertexBufferObject(vbo);
            
            glBufferData(GL_ARRAY_BUFFER,
                         4*sizeof(VertexData2D),
                         &vertices[0],
                         GL_STATIC_DRAW);
            
            GLuint ibo = [DNRTextureAtlas sharedQuadIndexBufferObject];
            
            bindIndexBufferObject(ibo);
            
            
            glEnableVertexAttribArray(flatPositionLocation);
            
            glVertexAttribPointer(flatPositionLocation, 2, GL_FLOAT, GL_FALSE, stride2D, positionOffset2D);
            
            // At this point the VAO is set up with two vertex attributes
            // referencing the same buffer object, and another buffer object
            // as source for index data. We can now unbind the VAO, go do
            // something else, and bind it again later when we want to render
            // with it.
            bindVertexArrayObject(0);
            
            glDisableVertexAttribArray(flatPositionLocation);
            
            bindIndexBufferObject(0);
            bindVertexBufferObject(0);
            
            free(vertices);
        }
    }
}


#pragma mark - Designated Initializers


- (instancetype) init {

    if ((self = [super init])) {
        
        _tintColor = Color4fWhite;
        
        _colorBlendFactor              = 0.0f;
        _complementaryColorBlendFactor = 1.0f;
        
        _scale = CGPointMake(1.0f, 1.0f);
        
        // Sprite defaults to blocking touches
        [self setUserInteractionEnabled:YES];
        // (set to NO when child of a control)
    }
    
    return self;
}


#pragma mark - Convenience Initializers


- (instancetype) initWithSize:(CGSize) size
                        color:(Color4f)color {
    
    if ((self = [self init])) {
        
        _nativeColor = color;
        
        _opaque = (_nativeColor.a >= 1.0f);
        
        _nativeSize = size;
    }
    
    return self;
}


- (instancetype) initWithSubimageNamed:(NSString *)subimageName
                        inTextureAtlas:(DNRTextureAtlas *)textureAtlas {

    if (subimageName) {
        return [self initWithSubimageNames:@[subimageName] inTextureAtlas:textureAtlas];
    }
    else{
        return (self = nil);
    }
}


- (instancetype) initWithSubimageNames:(NSArray *)subimageNames
                        inTextureAtlas:(DNRTextureAtlas *)atlas {

    if ((self = [self init])) {
        
        _subimageNames = [subimageNames copy];
        
        _textureAtlas  = atlas;
        
        _vao           = [_textureAtlas vertexArrayObjectForSubimageNames:_subimageNames];
        
        if (_vao == 0) {
            // Texture atlas has not loaded the vertex array object for this
            // sprite yet (can only be done in main OpenGL context/main thread);
            // register to listen to the completion event:
            
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(atlasLoadedVertexArrayObject:)
                                                         name:DNRAtlasLoadedVertexArrayObjectNotification
                                                       object:_textureAtlas];
            
            // (Draw calls are skipped until vao becomes non-zero)
        }
        
        _textureName   = [_textureAtlas textureName]; // needed for...?
        
        _currentSubimageIndex = 0;
        
        _nativeSize    = [_textureAtlas sizeForSubimageNamed:[_subimageNames objectAtIndex:0]];
    }
    
    return self;
}


- (instancetype) initWithAnimationSequenceNamed:(NSString* )scriptName {
    
    DNRFrameAnimationSequence *sequence = [DNRFrameAnimationSequence animationSequenceNamed:scriptName];
    
    return [self initWithAnimationSequence:sequence];
}


- (instancetype) initWithAnimationSequence:(DNRFrameAnimationSequence *)sequence {
    
    DNRTextureAtlas* atlas = [DNRTextureAtlas atlasNamed:[sequence atlasName]];
    
    NSArray* subimageNames = [sequence subimageNames];
    
    if (self = [self initWithSubimageNames:subimageNames inTextureAtlas:atlas]){
        
        [self setAnimationSequence:sequence];
    }
    
    return self;
}


#pragma mark - Factory Methods


+ (instancetype) spriteWithSize:(CGSize) size
                          color:(Color4f)color {
    
    return [[self alloc] initWithSize:size color:color];
}


+ (instancetype) spriteWithSubimageNamed:(NSString *)subimageName
                          inTextureAtlas:(DNRTextureAtlas *)atlas {

    return [[self alloc] initWithSubimageNamed:subimageName inTextureAtlas:atlas];
}


+ (instancetype) spriteWithSubimageNames:(NSArray *)subimageNames
                          inTextureAtlas:(DNRTextureAtlas *)atlas {

    return [[self alloc] initWithSubimageNames:subimageNames inTextureAtlas:atlas];
}


#pragma mark - Deinitializer


- (void) dealloc {
    
    [_textureAtlas relinquishVertexArrayObjectForSubimageNames:_subimageNames];
}


#pragma mark - Animation


- (void) startAnimatingWithCompletion:(void(^)(void))completion {
    
    _animationFrames = [[_animationSequence frames] copy];
    
    if ([_animationFrames count] < 1) {
        return;
    }
    
    _currentFrameIndex = 0;
    DNRSpriteFrame* firstFrame = [_animationFrames objectAtIndex:0];
    
    NSString* subimageName   = [firstFrame subimageName];
    NSUInteger subimageIndex = [_subimageNames indexOfObject:subimageName];
    
    if (subimageIndex == NSNotFound){
        return;
    }
    
    _currentSubimageIndex     = subimageIndex;
    _currentFrameDuration     = [firstFrame duration];
    _currentFrameEllapsedTime = 0.0f;
    
    _maxLoopCount = [_animationSequence repeatCount];
    _loopsLeft = _maxLoopCount;
    
    _animationCompletionHandler = completion;
    
    _animating = YES;
}


- (void) startAnimating {
    
    [self startAnimatingWithCompletion:NULL];
}


- (void) stopAnimating {

    _animating = NO;
}
/*
- (void) runAnimationSequence:(DNRFrameAnimationSequence *)sequence
                   completion:(void(^)(void))completion {
    
    _animationFrames = [[sequence frames] copy];
    
    if ([_animationFrames count] < 1) {
        return;
    }
    
    _currentFrameIndex = 0;
    DNRSpriteFrame* firstFrame = [_animationFrames objectAtIndex:0];
    
    NSString* subimageName   = [firstFrame subimageName];
    NSUInteger subimageIndex = [_subimageNames indexOfObject:subimageName];
    
    if (subimageIndex == NSNotFound){
        return;
    }
    
    _currentSubimageIndex     = subimageIndex;
    _currentFrameDuration     = [firstFrame duration];
    _currentFrameEllapsedTime = 0.0f;
    
    _animating = YES;
}
*/

#pragma mark - DNRNode


- (BOOL) swallowsTouches {
    /*
     Return YES to "swallow" a touch, regardless if it is claimed or not.
     
     Swallow means that the hit test for this touch during the touch began phase
     ends with this node, and all further nodes in depth order are skipped
     (touch is occluded).
     
     If, in addition, we claim the touch, we will also receive notifications for
     all further phases (moved, ended, cancelled).
     
     Examples:
     (A) An opaque sprite (DNRSprite) should block touches within its bounds
     from reaching (say) a button that lies beneath it, eventhough the sprite
     itself does not "react" to the touch (i.e., claim it) in any way.
     
     (B) A container node (DNRNode) should let touches "pass through" and 
     potentially reach any controls lying beneath it (lower z).
     
     */
    
    if ([[self parent] isKindOfClass:[DNRControl class]]) {
        return NO;
    }
    
    return YES;
}


- (BOOL) drawsSelf {
    
    if (_textureAtlas == nil) {
        // Solid sprite: always draws self.
        
        return YES;
    }
    else{
        // Textured sprite:If Vertex Array Object has not been loaded yet, the sprite returns 0 (NO)
        // and the call to -render is skipped, avoiding runtime errors.
        
        return _vao;    // == 0 (NO) if not loaded, != 0 (YES) if loaded.
    }
}


- (BOOL) needsBlending {
    
    if (_textureName) {
        // [A] TEXTURED
     
        return (!_opaque);  // Depends on current frame
    }
    else{
        // [B] SOLID
        
        if ([self alpha] < 1.0f) {  // TODO: Cache [self alpha] in ivar (and override setter)?
            return YES;
        }
        
        if (_nativeColor.a < 1.0f) {
            return YES;
        }
        
        return NO;
    }

    // ^ TODO: Test/improve
}


- (void) update:(CFTimeInterval) dt {
    if (_animating) {
        [self updateAnimation:dt];
    }
}


- (void) render {
    
    [self updateModelviewMatrix];
    
    float alpha = [self alpha]; // TODO: make alpha recursive (influenced by ancestors).
    
    
    if (_textureName) {
        // . .. . .. . .. . .. . .. . .. . .. . .. . .. . .. . .. . .. . .. . ..
        // [ A ] TEXTURED
        
        
        // 1. Update color and opacity
        
        _renderColor4f[0] = ((_colorBlendFactor*_tintColor.r) + (_complementaryColorBlendFactor * 1.0f))*alpha;
        _renderColor4f[1] = ((_colorBlendFactor*_tintColor.g) + (_complementaryColorBlendFactor * 1.0f))*alpha;
        _renderColor4f[2] = ((_colorBlendFactor*_tintColor.b) + (_complementaryColorBlendFactor * 1.0f))*alpha;
        _renderColor4f[3] = ((_colorBlendFactor*_tintColor.a) + (_complementaryColorBlendFactor * 1.0f))*alpha;
        
        
        // 2. Bind Texture
        
        bindTexture2D(_textureName);
        
        
        // 3. Bind shaders
        
        useProgram(program);
        
        
        // 4. Configure shaders
        
        uniform4fv(colorLocation, _renderColor4f);                  // Tint color and Opacity
        uniform1f(zLocation, [self z]);                             // Sprite Depth (Z order)
        glUniformMatrix4fv(modelviewLocation, 1, 0, _modelview4fv); // Position/Rotation/Scale
        
        
        // 5. Bind geometry
        
        bindVertexArrayObject(_vao);
        
        
        // 6. Draw
        
        GLvoid* startIndex = (GLvoid *)(sizeof(GLushort) * 4 * _currentSubimageIndex);
        // This should work (startIndex is in bytes, right? not shorts)
        
        glDrawElements(GL_TRIANGLE_STRIP, 4, GL_UNSIGNED_SHORT, (GLvoid *)startIndex);
        
        //bindVertexArrayObject(0);
        // -> This is inefficient when drawing several copies of the same sprite!
        // the next draw call will take care of binding the appropriate geomtery;
        // leave it as is!
    }
    else{
        // . .. . .. . .. . .. . .. . .. . .. . .. . .. . .. . .. . .. . .. . ..
        // [ B ] SOLID
        
        _renderColor4f[0] = ((_colorBlendFactor*_tintColor.r) + (_complementaryColorBlendFactor*_nativeColor.r))*alpha;
        _renderColor4f[1] = ((_colorBlendFactor*_tintColor.g) + (_complementaryColorBlendFactor*_nativeColor.g))*alpha;
        _renderColor4f[2] = ((_colorBlendFactor*_tintColor.b) + (_complementaryColorBlendFactor*_nativeColor.b))*alpha;
        _renderColor4f[3] = ((_colorBlendFactor*_tintColor.a) + (_complementaryColorBlendFactor*_nativeColor.a))*alpha;
        
        
        // .. ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ..
        // 3. Bind shaders
        
        useProgram(flatProgram);
        
        
        // .. ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ..
        // 4. Configure shaders
        
        uniform4fv(flatColorLocation, _renderColor4f);                  // Tint color and Opacity
        uniform1f(flatZLocation, [self z]);                             // Sprite Depth (Z order)
        glUniformMatrix4fv(flatModelviewLocation, 1, 0, _modelview4fv); // Position/Rotation/Scale
        
        
        // .. ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ..
        // 5. Bind geometry
        
        bindVertexArrayObject(flatVAO);
        
        
        // .. ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ..
        // 6. Draw
        
        
        glDrawElements(GL_TRIANGLE_STRIP, 4, GL_UNSIGNED_SHORT, 0);
        
        //bindVertexArrayObject(0);
        // -> This is inefficient when drawing several copies of the same sprite!
        // the next draw call will take care of binding the appropriate geomtery;
        // leave it as is!
    }
}


#pragma mark - Custom Accessors


- (void) setXScale:(CGFloat)xScale {
    _scale.x = xScale;
}


- (CGFloat) xScale {
    return _scale.x;
}


- (void) setYScale:(CGFloat)yScale {
    _scale.y = yScale;
}


- (CGFloat) yScale {
    return _scale.y;
}


- (void) setColorBlendFactor:(CGFloat)colorBlendFactor {
    _colorBlendFactor = colorBlendFactor;
 
    if (_colorBlendFactor < 0.0f) {
        _colorBlendFactor = 0.0f;
    }
    else if(_colorBlendFactor > 1.0f){
        _colorBlendFactor = 1.0f;
    }
    
    _complementaryColorBlendFactor = 1.0f - colorBlendFactor;
}


- (void) setVertexArrayObject:(GLuint) vao {
    if (vao != _vao) {
        // Different value
        
        BOOL wasZero = (_vao == 0);
        
        _vao = vao;
        
        if (wasZero) {
            // Went from zero to non-zero (i.e., beacme ready to draw)
            
            [[NSNotificationCenter defaultCenter] postNotificationName:DNRSpriteBecameReadyNotification
                                                                object:self];
        }
    }
}


#pragma mark - Operation


- (void) updateModelviewMatrix {
    
    if (_textureName) {
        // . .. . .. . .. . .. . .. . .. . .. . .. . .. . .. . .. . .. . .. . ..
        // [ A ] TEXTURED
        
        // Calculates the current modelview transform, based on ancestors.
        // Called just before rendering.
     
        static GLfloat  scaleMatrix[16];
        static GLfloat* worldTransform;
        
        
        worldTransform = [self worldTransform];
        
        // Apply Scale
        
        _scale3f[0] = _scale.x;
        _scale3f[1] = _scale.y;
        _scale3f[2] = 1.0f;
        // Z-axis scale must always be 1.0f (otherwise depth gets f.ed up)
        
        mat4f_LoadScale(_scale3f, scaleMatrix);
        
        scaleMatrix[0] *= screenScaleFactor;
        scaleMatrix[5] *= screenScaleFactor;
        // (modelview matrix is in pixels)
        
        
        mat4f_MultiplyMat4f(worldTransform, scaleMatrix, _modelview4fv);
    }
    else{
        // . .. . .. . .. . .. . .. . .. . .. . .. . .. . .. . .. . .. . .. . ..
        // [ B ] SOLID

        
        // Calculates the current modelview transform, based on ancestors.
        // Called just before rendering.
        
        static GLfloat  scaleMatrix[16];
        static GLfloat* worldTransform;
        
        
        worldTransform = [self worldTransform];
        
        // Apply Scale
        
        _scale3f[0] = _scale.x * _nativeSize.width;
        _scale3f[1] = _scale.y * _nativeSize.height;
        // Solid sprites use a (shared) unit quad as base geometry. Native size must
        // be factored into this step. In contrast, textured sprites use geometry
        // that is already at the native size, so _scale alone is used)
        
        _scale3f[2] = 1.0f;
        // Z-axis scale must always be 1.0f (otherwise depth gets f.ed up)
        
        mat4f_LoadScale(_scale3f, scaleMatrix);
        
        scaleMatrix[0] *= screenScaleFactor;
        scaleMatrix[5] *= screenScaleFactor;
        // (modelview matrix is in pixels)
        
        
        mat4f_MultiplyMat4f(worldTransform, scaleMatrix, _modelview4fv);
    }
    
    // TODO: Move common code out of if/else blocks
}

// TEST

- (void) updateBoundingFrame {

    static GLfloat v0[4] = {0.0f};
    static GLfloat v1[4] = {0.0f};
    static GLfloat v2[4] = {0.0f};
    static GLfloat v3[4] = {0.0f};
    
    static GLfloat p0[4] = {0.0f};
    static GLfloat p1[4] = {0.0f};
    static GLfloat p2[4] = {0.0f};
    static GLfloat p3[4] = {0.0f};
    
    static GLfloat* outVectors[4] = {p0, p1, p2, p3};
    
    
    
    GLfloat xMin = -0.5f*(_nativeSize.width)*screenScaleFactor;
    GLfloat xMax = -xMin;
    
    GLfloat yMin = -0.5f*(_nativeSize.height)*screenScaleFactor;
    GLfloat yMax = -yMin;
    
    
    // top left
    v0[0] = xMin;   v0[1] = yMax;   v0[2] = 0.0f;   v0[3] = 1.0f;
    
    // bottom left
    v1[0] = xMin;   v1[1] = yMin;   v1[2] = 0.0f;   v1[3] = 1.0f;
    
    // top right
    v2[0] = xMax;   v2[1] = yMax;   v2[2] = 0.0f;   v2[3] = 1.0f;
    
    // bottom right
    v3[0] = xMax;   v3[1] = yMin;   v3[2] = 0.0f;   v3[3] = 1.0f;
    
    
    mat4f_MultiplyVec4f(_modelview4fv, v0, p0);
    mat4f_MultiplyVec4f(_modelview4fv, v1, p1);
    mat4f_MultiplyVec4f(_modelview4fv, v2, p2);
    mat4f_MultiplyVec4f(_modelview4fv, v3, p3);
    
    
    xMin = +INFINITY;
    xMax = -INFINITY;
    yMin = +INFINITY;
    yMax = -INFINITY;
    
    for (int i=0; i < 4; i++) {
        
        GLfloat* p = outVectors[i];
     
        if (p[0] < xMin) {
            xMin = p[0];
        }
        if (p[0] > xMax) {
            xMax = p[0];
        }
        
        if (p[1] < yMin) {
            yMin = p[1];
        }
        if (p[1] > yMax) {
            yMax = p[1];
        }
    }
    
    _boundsX0 = xMin;
    _boundsX1 = xMax;
    _boundsY0 = yMin;
    _boundsY1 = yMax;
}


- (void) goToNextFrame {
    _currentSubimageIndex = (_currentSubimageIndex + 1) % [_subimageNames count];
}


- (void) setSubimageIndex:(NSUInteger) index {
    
    _currentSubimageIndex = index % [_subimageNames count]; // (wrap)
    
    // Update native size and alpha blending flag
    
    NSString* currentName = _subimageNames[_currentSubimageIndex];
    
    _nativeSize = [_textureAtlas sizeForSubimageNamed:currentName];
    _opaque     = [_textureAtlas subimageIsOpaque:currentName];
    
    [self setSize:_nativeSize];
}


- (void) updateAnimation: (CFTimeInterval) dt {

    _currentFrameEllapsedTime += dt;
    
    if (_currentFrameEllapsedTime >= _currentFrameDuration) {
        
        if (_maxLoopCount != -1){
            // Animation is NOT infinite loop;
            
            if (_currentFrameIndex == [_animationFrames count] - 1){
                // And we finished the last frame
                
                if (_loopsLeft == 1){
                    // We are on the last repetition
                    _animating = NO;
                    
                    if (_animationCompletionHandler != nil){
                        _animationCompletionHandler();
                        _animationCompletionHandler = nil;
                    }
                    return;
                }
                
                _loopsLeft--;
            }
        }
        
        
        CFTimeInterval surplus = _currentFrameEllapsedTime - _currentFrameDuration;
        
        // Move to the next frame:
        
        _currentFrameIndex = (_currentFrameIndex + 1) % [_animationFrames count];
        
        DNRSpriteFrame *nextFrame = [_animationFrames objectAtIndex:_currentFrameIndex];
        
        NSString  *subimageName  = [nextFrame subimageName];
        NSUInteger subimageIndex = [_subimageNames indexOfObject:subimageName];
        
        if (subimageIndex == NSNotFound) {
            _animating = NO;
            return;
        }
        _currentSubimageIndex = subimageIndex;
        
        _currentFrameDuration     = [nextFrame duration];
        _currentFrameEllapsedTime = surplus; // Delay doesn't add up
    }
}


- (BOOL) pointInGlobalCoordinatesIsWithinBounds:(CGPoint) globalPoint
                                  withTolerance:(CGFloat) tolerance {
    
    float inverseWorldMatrix[16] = { 0.0f };
    
    mat4f_Invert([self worldTransform], inverseWorldMatrix);
    
    float vectorIn[4];
    float vectorOut[4] = { 0.0f };
    
    // All matrices are in pixels:
    vectorIn[0] = globalPoint.x * screenScaleFactor;
    vectorIn[1] = globalPoint.y * screenScaleFactor;
    vectorIn[2] = 0.0f;
    vectorIn[3] = 1.0f;
    

    mat4f_MultiplyVec4f(inverseWorldMatrix, vectorIn, vectorOut);
    
    
    CGPoint localpoint = CGPointMake(vectorOut[0]/screenScaleFactor, vectorOut[1]/screenScaleFactor);
    
    CGSize size = [self size];
    
    // Compare local point against bounds:
    
    if (fabs(localpoint.x) <= 0.5f*(size.width)) {
        if (fabs(localpoint.y) <= 0.5f*(size.height)) {
            return YES;
        }
    }
    
    return NO;
}


#pragma mark - Custom Accessors


- (void) setSize:(CGSize) size {
    /* 
     Sets size in points. Size is a calculated property, so in reality we
     manipulate maginification factor so as to obtain the desired effective
     size.
     */
    
    _scale.x = (size.width ) / (_nativeSize.width );
    _scale.y = (size.height) / (_nativeSize.height);
}


- (CGSize) size {
    
    static CGSize size;
    
    size.width  = (_nativeSize.width ) * (_scale.x);
    size.height = (_nativeSize.height) * (_scale.y);
    
    return size;
}


#pragma mark - Notifcation Handlers


- (void) atlasLoadedVertexArrayObject:(NSNotification *)notification {
    
    if ([notification object] == _textureAtlas) {
        // Own atlas
        
        NSArray* images = [[notification userInfo] objectForKey:kDNRAtlasLoadedVertexArrayObjectSumbimageNamesKey];
        
        if (images == _subimageNames) {
            
            // Own subscription
            [[NSNotificationCenter defaultCenter] removeObserver:self];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:DNRSpriteBecameReadyNotification
                                                                object:self];
        }
    }
}


@end
