//
//  DNRShaderManager.m
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-03-08.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import "DNRBase.h"

#import "DNRShaderManager.h"


#if defined(DNRPlatformPhone)

// Prepend this string to all shader sources on iOS:
#define ShaderSourcePreface @"#version 100\n\n"

#elif defined(DNRPlatformMac)

// Prepend this string to all shader sources on OS X:
//#define ShaderSourcePreface @""

#define ShaderSourcePreface @"#version 150 \n#define highp \n#define mediump \n#define lowp\n\n"

#endif

#define VertexShaderExtension       @"vertsh"
#define FragmentShaderExtension     @"fragsh"


enum{
    
	ShaderTexturedSprite = 0,
    // Color (tint) is specified as a uniform (common to all vertices)
	

    ShaderTexturedSpriteWithPerVertexColor,
    // Color (tint) is specified as an attribute (per-vertex)
    
    ShaderTexturedSpriteWithAlphaTest,
    // Performs alpha testing (useful for stencil masking)
    
    ShaderTexturedSpriteDesaturated,
    // Draws in luminance-weight-averaged grayscale
    
    ShaderFlatSprite,
    // Draws uniform color only, no texture
    
    
	ShaderCount
};


@implementation DNRShaderManager {

    /* Default Programs: Loaded unconditionally on startup
    */
    GLuint* _defaultPrograms;
    
    
    /* Custom Programs: User defined, loaded optionally on demand
    */
    NSMutableDictionary* _customPrograms;
}



+ (instancetype) defaultManager {

    static id sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}


- (id) init {

    if ((self = [super init])) {
        
        _defaultPrograms = calloc(ShaderCount, sizeof(GLuint));
        
        _customPrograms = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}


- (NSBundle *)bundle {

    return [NSBundle bundleForClass:[self class]];
}


- (void) setProgram:(GLuint) program forObject:(NSUInteger) index {

    if (index < ShaderCount) {
        _defaultPrograms[index] = program;
    }
}


- (GLuint) programForObject:(NSUInteger) index {

    if (index < ShaderCount) {
        return _defaultPrograms[index];
    }
    
    return 0;
}


- (GLuint) spriteProgram {

    // (Declared as read-only @property)
    
    return [self programForObject:ShaderTexturedSprite];
}


- (GLuint) spriteProgramWithPerVertexColor {

    return [self programForObject:ShaderTexturedSpriteWithPerVertexColor];
}


- (GLuint) spriteProgramWithAlphaTest {

    return [self programForObject:ShaderTexturedSpriteWithAlphaTest];
}


- (GLuint) flatProgram {

    // (Declared as read-only @property)
    
    return [self programForObject:ShaderFlatSprite];
}





- (GLuint) defaultProgram {

    return _defaultPrograms[ShaderTexturedSprite];
}


- (GLuint) compileShaderWithSource:(const char *)source
                            ofType:(GLenum) shaderType {

    if (shaderType != GL_VERTEX_SHADER && shaderType != GL_FRAGMENT_SHADER) {
        NSLog(@"Error: Invalid Shader Type.");
        return -1;
    }
    
    // Create Object
    GLuint shaderHandle = glCreateShader(shaderType);
    
    // Read Source Code Text
    glShaderSource(shaderHandle, 1, &source, 0);
    
    // Compile
    glCompileShader(shaderHandle);
    
#ifdef DEBUG
    // Validate
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
		glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
		NSLog(@"%s", messages);
		exit(1);
    }
    
#endif
    return shaderHandle;
}


- (GLuint) buildProgramWithVertexShaderSource:(const char *)vertexSource
                         fragmentShaderSource:(const char *)fragmentSource {

    float  glLanguageVersion;
    
    //const unsigned char* versionString = glGetString(GL_SHADING_LANGUAGE_VERSION);
    //DLog(@"Version: %s", versionString); // "OpenGL ES GLSL ES 3.00" or "4.10"
    
    
#if defined(DNRPlatformPhone)
    sscanf((char *)glGetString(GL_SHADING_LANGUAGE_VERSION), "OpenGL ES GLSL ES %f", &glLanguageVersion);
#else
    sscanf((char *)glGetString(GL_SHADING_LANGUAGE_VERSION), "%f", &glLanguageVersion);
#endif
    // GL_SHADING_LANGUAGE_VERSION returns the version standard version form
    //  with decimals, but the GLSL version preprocessor directive simply
    //  uses integers (thus 1.10 should be 110 and 1.40 should be 140, etc.)
    //  We multiply the floating point number by 100 to get a proper
    //  number for the GLSL preprocessor directive
    GLuint version = 100 * glLanguageVersion;
    
    
    // Get the size of the version preprocessor string info so we know
    //  how much memory to allocate for our sourceString
    #if defined(DNRPlatformPhone)
    const GLsizei versionStringSize = sizeof("#version 123 es\n");
    #else
    const GLsizei versionStringSize = sizeof("#version 123\n");
    #endif
    
    // Create a program object
    GLuint programHandle = glCreateProgram();
    
    /*
     https://developer.apple.com/library/content/documentation/3DDrawing/Conceptual/OpenGLES_ProgrammingGuide/AdoptingOpenGLES3/AdoptingOpenGLES3.html
     */
    
    char* extendedVertexSource   = malloc(strlen(vertexSource  ) + versionStringSize);
    char* extendedFragmentSource = malloc(strlen(fragmentSource) + versionStringSize);

    #if defined(DNRPlatformPhone)
    sprintf(extendedVertexSource,   "#version %d es\n%s", version, vertexSource  );
    sprintf(extendedFragmentSource, "#version %d es\n%s", version, fragmentSource);
    #else
    sprintf(extendedVertexSource,   "#version %d\n%s", version, vertexSource  );
    sprintf(extendedFragmentSource, "#version %d\n%s", version, fragmentSource);
    #endif
    
    //NSString* deb1 = [NSString stringWithCString:extendedFragmentSource encoding:NSASCIIStringEncoding];
    //NSString* deb2 = [NSString stringWithCString:extendedVertexSource encoding:NSASCIIStringEncoding];
    //NSLog(@"%@", deb1);
    //NSLog(@"%@", deb2);
    
    // Compile individual shaders
    GLuint vertexShader   = [self compileShaderWithSource:extendedVertexSource   ofType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShaderWithSource:extendedFragmentSource ofType:GL_FRAGMENT_SHADER];
    
    
    
    // Attach Shaders
    glAttachShader(programHandle, vertexShader);
    glAttachShader(programHandle, fragmentShader);
    
    // Link Program
    glLinkProgram(programHandle);
    
#ifdef DEBUG
    // Validate
    GLint linkSuccess;
    
    glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
    
    if (linkSuccess == GL_FALSE) {
		GLchar messages[256];
		glGetProgramInfoLog(programHandle, sizeof(messages), 0, &messages[0]);
		NSLog(@"%s", messages);
		exit(1);
	}
#endif
    
    return programHandle;
}


- (GLuint) buildProgramFromVertexShaderName:(NSString *)vertexShaderName
                         fragmentShaderName:(NSString *)fragmentShaderName {

    GLuint programHandle = 0;
    
    NSString* vertexPath = [[self bundle] pathForResource:vertexShaderName
                                                   ofType:VertexShaderExtension];
    
    NSString* vertexSource = [[NSString alloc] initWithContentsOfFile:vertexPath
                                                         usedEncoding:nil
                                                                error:nil];
    if (!vertexSource) {
        NSLog(@"-[DNRShaderManager buildProgramFromVertexShaderName:fragmentShaderName:]: Fatal Error. Shader source is nil.");
        return 0;
    }
    
    //vertexSource = [ShaderSourcePreface stringByAppendingString:vertexSource];
    
    NSString* fragmentPath = [[self bundle] pathForResource:fragmentShaderName
                                                     ofType:FragmentShaderExtension];
    
    NSString* fragmentSource = [[NSString alloc] initWithContentsOfFile: fragmentPath
                                                           usedEncoding:nil
                                                                  error:nil];
    if (!fragmentSource) {
        NSLog(@"-[DNRShaderManager buildProgramFromVertexShaderName:fragmentShaderName:]: Fatal Error. Shader source is nil.");
        return 0;
    }
    
    //fragmentSource = [ShaderSourcePreface stringByAppendingString:fragmentSource];
    
    if (vertexSource && fragmentSource) {
        
        const char* vertexCString   = [vertexSource cStringUsingEncoding:NSUTF8StringEncoding];
        const char* fragmentCString = [fragmentSource cStringUsingEncoding:NSUTF8StringEncoding];
        
        programHandle = [self buildProgramWithVertexShaderSource:vertexCString
                                            fragmentShaderSource:fragmentCString];
        
        if (programHandle) {
            // SUCCESS; Register into Database:
            
            NSString* key;
            
            if ([vertexShaderName isEqualToString:fragmentShaderName]) {
                key = vertexShaderName;
            }
            else{
                key = [NSString stringWithFormat:@"%@+%@", vertexShaderName, fragmentShaderName];
            }
            
            [_customPrograms setValue:[NSNumber numberWithUnsignedInt:programHandle] forKey:key];
        }
    }
    
    return programHandle;
}


- (GLuint) buildProgramNamed:(NSString *)programName {
    
    return [self buildProgramFromVertexShaderName:programName
                               fragmentShaderName:programName];
}


- (GLuint) programWithVertexShaderNamed:(NSString *)vertexName
                 andFragmentShaderNamed:(NSString *)fragmentName {
    
    NSString* key;
    
    if ([vertexName isEqualToString:fragmentName]) {
        key = vertexName;
    }
    else{
        key = [NSString stringWithFormat:@"%@+%@", vertexName, fragmentName];
    }
    
    GLuint programHandle = [[_customPrograms objectForKey:key] unsignedIntValue];
    
    if (!programHandle) {
        // Program does not exist; Compile
        
        programHandle = [self buildProgramFromVertexShaderName:vertexName
                                            fragmentShaderName:fragmentName];
        
        if (programHandle) {
            [_customPrograms setValue:[NSNumber numberWithUnsignedInteger:programHandle]
                               forKey:key];
        }
        else{
            NSLog(@"ERROR! Failed to build program %@", key);
        }
    }
    
    return programHandle;
}


- (GLuint) programNamed:(NSString *)programName {
    
    // Search Database for Cached ID of Existing Program:
    
	GLuint programHandle = [[_customPrograms objectForKey:programName] unsignedIntValue];
	
	if (!programHandle) {
        // Not Found; Attempt Build
        
		programHandle = [self buildProgramFromVertexShaderName:programName
                                            fragmentShaderName:programName];
	}
	
	return programHandle; //( = 0 if not found )
}


- (BOOL) initializeDefaultPrograms {
    
    // [ 1 ] Sprite (standard)
    
    GLuint spriteProgram = [self buildProgramNamed:@"Sprite"];
    
    if (!spriteProgram) {
        return NO;
    }
    
    _defaultPrograms[ShaderTexturedSprite] = spriteProgram;
    

    /*
    // [1.b] Sprite (per-vertex color)
    
    GLuint spriteVertexColorProgram = [self buildProgramFromVertexShaderName:@"SpritePerVertexColor"
                                                          fragmentShaderName:@"Sprite"];
    if (!spriteVertexColorProgram) {
        return NO;
    }
    
    _defaultPrograms[ShaderTexturedSpriteWithPerVertexColor] = spriteVertexColorProgram;
    

    // [ 2 ] Alpha test
    
    GLuint spriteAlphaTestProgram = [self buildProgramFromVertexShaderName:@"Sprite"
                                                        fragmentShaderName:@"SpriteAlphaTest"];
    if (!spriteAlphaTestProgram) {
        return NO;
    }
    
    _defaultPrograms[ShaderTexturedSpriteWithAlphaTest] = spriteAlphaTestProgram;
    
    
    // [ 3 ] Desaturated (grayscale)
    
    GLuint spriteDesaturateProgram = [self buildProgramFromVertexShaderName:@"Sprite"
                                                         fragmentShaderName:@"SpriteAlphaTest"];
    if (!spriteDesaturateProgram) {
        return NO;
    }
    
    _defaultPrograms[ShaderTexturedSpriteDesaturated] = spriteDesaturateProgram;
    
    */
    
    // [ 4 ] Flat shading (no texture, just solid color)
    
    GLuint flatProgram = [self buildProgramNamed:@"Flat"];
    
    if (!flatProgram) {
        return NO;
    }
    
    _defaultPrograms[ShaderFlatSprite] = flatProgram;
    
    
    return YES;
}

@end
