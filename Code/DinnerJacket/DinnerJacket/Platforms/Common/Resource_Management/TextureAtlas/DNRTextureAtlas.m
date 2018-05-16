//
//  DNRTextureAtlas.m
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-05-02.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import "DNRTextureAtlas.h"

#import "DNRTexture.h"
#import "DNRShaderManager.h"

#import "DNRGLCache.h"
#import "DNRGlobals.h"                                  // Stride, etc.

#import "CGSupport.h"

#import <CommonCrypto/CommonDigest.h>


// Exported constants
NSString* const kDNRTextureAtlasOptionsShareGroupKey              = @"ShareGroup";
NSString* const DNRAtlasLoadedVertexArrayObjectNotification       = @"AtlasLoadedVertexArrayObject";
NSString* const kDNRAtlasLoadedVertexArrayObjectSumbimageNamesKey = @"SubimageNames";

// Private constants
static NSString* const kDNRTextureAtlasVAOKey      = @"vao";
static NSString* const kDNRTextureAtlasVBOKey      = @"vbo";
static NSString* const kDNRTextureAtlasIBOKey      = @"ibo";
static NSString* const kDNRTextureAtlasUseCountKey = @"useCount";

// Shared objects
static GLuint textureAtlasSharedQuadIBO = 0u;
static GLuint textureAtlasSharedMeshIBO = 0u;
static NSMutableDictionary* textureAtlasesByName = nil;

// Helper functions
NSString* DNRTextureAtlasImageFilePath( NSDictionary* dictionary ) {
    
    NSString* imageName      = [dictionary objectForKey:@"ImageName"];
    
    if ([[imageName pathExtension] length] == 0) {
        imageName = [imageName stringByAppendingPathExtension:@"png"];
    }
    
    NSString* imageDirectory = [dictionary objectForKey:@"ImageDirectory"];
    NSString* imageFullPath = nil;
    
    if (!imageDirectory) {
        // [ A ] Directory NOT specified; default to Resources:
        
        NSString* resourcePath = [[NSBundle mainBundle] resourcePath];
        
        imageFullPath = [resourcePath stringByAppendingPathComponent:imageName];
    }
    else{
        // [ B ] Directory specified: assume relative to app home directory
        
        imageFullPath = [NSHomeDirectory() stringByAppendingPathComponent:imageDirectory];
        imageFullPath = [imageFullPath stringByAppendingPathComponent:imageName];
    }
    
    return imageFullPath;
}

// .............................................................................


@interface DNRTextureAtlas ()

/// Status.
@property (nonatomic, readwrite) BOOL                   loaded;


/// Reference to the texture, kept in order to relinquish ownership on
/// deallocation (in turn allows for texture purging). Also used to query image
/// size on VAO creation.
@property (nonatomic, readwrite) DNRTexture*            texture;


/// Holds all the subimage rects (in points) keyed by subimage name
@property (nonatomic, readwrite) NSMutableDictionary*   database;


///
@property (nonatomic, readwrite) NSMutableDictionary*   vaoDatabase;


///
@property (nonatomic, readwrite) NSMutableDictionary*   iboDatabase;


/// Cummulative use count of all Vertex Array Objects. (when 0, texture atlas
/// can be safely deallocated)
@property (nonatomic, readwrite) NSInteger vaoTotalUseCount;

@end


@implementation DNRTextureAtlas


#pragma mark - Factory / Management


+ (void) initialize {

    if (self == [DNRTextureAtlas class]) {
        
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
        
            textureAtlasesByName = [NSMutableDictionary new];
            
            // Initialize shared objects synchronously on main thread
            
            dispatch_block_t block = ^{
                
                // 1. Shared index buffer object (Simple Quad)
                
                if (textureAtlasSharedQuadIBO == 0u) {
                    
                    GLushort quadIndices[4] = {0, 1, 2, 3};
                    
                    glGenBuffers(1, &textureAtlasSharedQuadIBO);
                    bindIndexBufferObject(textureAtlasSharedQuadIBO);
                    
                    glBufferData(GL_ELEMENT_ARRAY_BUFFER, 4*sizeof(GLushort), &quadIndices, GL_STATIC_DRAW);
                    
                    bindIndexBufferObject(0);
                }
                
                // 2. Shared index buffer object (9-Slice Mesh)
                
                if (textureAtlasSharedMeshIBO) {
                    
                    GLushort meshIndices[28] = { // Three rows
                        0,  1,  2,  3,  4,  5,  6,  7,
                        7,  // <- Repeat last
                        
                        8,  // <- Repeat first
                        8,  9, 10, 11, 12, 13, 14, 15,
                        15,  // <- Repeat last
                        
                        16,  // <- Repeat first
                        16, 17, 18, 19, 20, 21, 22, 23
                    };
                    
                    glGenBuffers(1, &textureAtlasSharedMeshIBO);
                    bindIndexBufferObject(textureAtlasSharedMeshIBO);
                    
                    glBufferData(GL_ELEMENT_ARRAY_BUFFER, 28*sizeof(GLushort), &meshIndices[0], GL_STATIC_DRAW);
                    
                    bindIndexBufferObject(0);
                }
            };

            if ([NSThread isMainThread]) {
                block();
            }
            else{
                dispatch_sync(dispatch_get_main_queue(), block);
            }
        });
    }
}


+ (DNRTextureAtlas *)atlasNamed:(NSString *)atlasName {

    // Check if cached:
    
    DNRTextureAtlas* atlas = [textureAtlasesByName objectForKey:atlasName];
    if(atlas){
        return atlas;
    }
    
    // Not cached; Create it:
    
    NSString* path = [[NSBundle mainBundle] pathForResource:atlasName ofType:@"plist"];
    return [self textureAtlasWithContentsOfFile:path];
}


+ (DNRTextureAtlas *)textureAtlasWithContentsOfFile:(nonnull NSString *)path {
    
    NSDictionary* dictionary = [NSDictionary dictionaryWithContentsOfFile:path];
    
    if (!dictionary) {
        return nil;
    }
    
    DNRTexture *texture = [DNRTexture textureWithContentsOfFile:DNRTextureAtlasImageFilePath(dictionary)
                                                        options:nil];
    
    DNRTextureAtlas *textureAtlas = [[DNRTextureAtlas alloc] initWithTexture:texture
                                                   database:[dictionary objectForKey:@"Database"]
                                                    options:nil];
    if (textureAtlas) {
        NSString* atlasName = [[path lastPathComponent] stringByDeletingPathExtension];
        [textureAtlasesByName setObject:textureAtlas forKey:atlasName];
    }
    
    return textureAtlas;
}


+ (void) loadTextureAtlasWithContentsOfFile:(NSString *)path
                                 completion:(DNRResourceLoadingCompletionHandler) completionHandler {

    DNRTextureAtlas* textureAtlas = [textureAtlasesByName objectForKey:path];
    
    if (textureAtlas) {
        // CACHE HIT: Return it via completion handelr on the main thread.

        if ([NSThread isMainThread]) {
            completionHandler(@[textureAtlas]);
        }
        else{
            dispatch_async( dispatch_get_main_queue(), ^{ // MAIN THREAD
                completionHandler(@[textureAtlas]);
            });
        }
    }
    else{
        // CACHE MISS: Load in the background and return via completion handler
        // on the main thread.
        
        NSDictionary* dictionary = [NSDictionary dictionaryWithContentsOfFile:path];
        
        DNRResourceLoadingCompletionHandler completion = ^(NSArray* loadedObjects){
            
            DNRTextureAtlas* textureAtlas = nil;
            
            if ([loadedObjects count] == 1) {
                // Texture is or was loaded: Proceed.
                
                DNRTexture*   texture  = [loadedObjects objectAtIndex:0];
                NSDictionary* database = [dictionary objectForKey:@"Database"];
                
                textureAtlas = [[DNRTextureAtlas alloc] initWithTexture:texture
                                                               database:database
                                                                options:nil];
                
                [textureAtlasesByName setObject:textureAtlas forKey:path];
                
                if ([NSThread isMainThread]) {
                    completionHandler(@[textureAtlas]);
                }
                else{
                    dispatch_async( dispatch_get_main_queue(), ^{
                        // (MAIN THREAD)
                        completionHandler(@[textureAtlas]);
                    });
                }
                
            }
            else{
                // Texture not loaded and failed to load.
                
                dispatch_async( dispatch_get_main_queue(), ^{ // (MAIN THREAD)
                    completionHandler(nil);
                });
            }
        };
        
        [DNRTexture loadTextureWithContentsOfFile:DNRTextureAtlasImageFilePath(dictionary)
                                          options:nil
                                       completion:completion];
    }
}


+ (void) loadTextureAtlasNamed:(NSString *)atlasName
                    completion:(DNRResourceLoadingCompletionHandler) completionHandler {

    NSString* path = [[NSBundle mainBundle] pathForResource:atlasName ofType:@"plist"];
    
    return [DNRTextureAtlas loadTextureAtlasWithContentsOfFile:path
                                                    completion:completionHandler];
}


+ (GLuint) sharedQuadIndexBufferObject {

    return textureAtlasSharedQuadIBO;
}


+ (GLuint) sharedMeshIndexBufferObject {

    return textureAtlasSharedQuadIBO;
}


+ (void) purgeUnusedAtlases {
    
    NSMutableArray* keysToDelete = [NSMutableArray new];
    
    for (NSString* key in [textureAtlasesByName allKeys]) {
        DNRTextureAtlas* textureAtlas = [textureAtlasesByName objectForKey:key];
        
        if ([textureAtlas canSafelyDelete]) {
            [keysToDelete addObject:key];
        }
    }
    
    [textureAtlasesByName removeObjectsForKeys:keysToDelete];
}


#pragma mark - Custom Accessors


- (GLuint) textureName {

    return [_texture name];
}


#pragma mark - Designated Initializer


- (instancetype) initWithTexture:(DNRTexture *)texture
                        database:(NSDictionary *)database
                         options:(NSDictionary *)options {

    if ((self = [super init])) {
        
        
        // Holds the subregion (rectangle), in points, for each named subimage
        //  in the texture associated with this atlas
        
        _database = [NSMutableDictionary dictionaryWithDictionary:database];
        
        
        // Holds all the geometry associated with each set of subimages
        // Each entry is created on demand and cached.
        
        _vaoDatabase = [NSMutableDictionary new];
        
        
        // Holds the associated texture

        _texture = texture;
        [_texture aquire];
    }
    
    return self;
}


- (void) dealloc {
    
    [_texture relinquish];
    
    
    // Delete all cached OpenGL ES objects:
    
    for (NSDictionary* entry in [_vaoDatabase allValues]) {
        
        GLuint vao = [[entry objectForKey:kDNRTextureAtlasVAOKey] unsignedIntValue];
        //glDeleteVertexArraysOES(1, &vao);
        glDeleteVertexArrays(1, &vao);
        
        GLuint vbo = [[entry objectForKey:kDNRTextureAtlasVBOKey] unsignedIntValue];
        glDeleteBuffers(1, &vbo);
        
        GLuint ibo = [[entry objectForKey:kDNRTextureAtlasIBOKey] unsignedIntValue];
        glDeleteBuffers(1, &ibo);
    }
}


- (CGRect) rectangleForSubimageNamed:(NSString *)subimageName {

    /* The vertex geometry is already set to the native size of each sprite 
        frame, so this method is not needed for sprite creation.
       
       However, a sprite needs to know the point size of each of its frames in 
        order to scale to the appropriate magnification factor when
        set to an arbitrary point size.
     */
    
    CGRect rectangle = CGRectNull;
    
    NSDictionary* subimageDictionary = [_database objectForKey:subimageName];
    
    if (subimageDictionary) {
        // Found
     
        NSString* rectString = [subimageDictionary objectForKey:@"Rectangle"];
        rectangle = CGRectFromString(rectString);
    }
    
    return rectangle;
}


- (BOOL) subimageIsOpaque:(NSString *)subimageName {

    NSDictionary* subimageDictionary = [_database objectForKey:subimageName];
    
    if (subimageDictionary) {
        
        NSNumber* number = [subimageDictionary objectForKey:@"Opaque"];
        
        if (number) {
            return [number boolValue];
        }
    }
    
    return NO;
}


- (CGSize) sizeForSubimageNamed:(NSString *)subimageName {
    /* 
     The vertex geometry is already set to the native size of each sprite frame, 
     so this method is not needed for sprite creation.
     However, a sprite needs to know the point size of each of its frames in
     order to scale to the appropriate magnification factor when set to an arbitrary point size.
     */
    CGRect rectangle = [self rectangleForSubimageNamed:subimageName];
    
    return (rectangle.size);
}


- (void) relinquishVertexArrayObjectForSubimageNames:(NSArray *)subimageNames {
    
    // Calcualte the dictionary key associated with the image name set:
    NSString* key = [self dictionaryKeyForSubimageNames:subimageNames];
    
    NSMutableDictionary* entry = [_vaoDatabase objectForKey:key];
    
    if (entry) {
        
        NSInteger useCount = [[entry objectForKey:kDNRTextureAtlasUseCountKey] integerValue];
        useCount--;
        
        if (useCount < 0) {
            // Error; handle it!
        }
        
        [entry setObject:@(useCount) forKey:kDNRTextureAtlasUseCountKey];
        
        _vaoTotalUseCount--;
        
        if (_vaoTotalUseCount < 0) {
            // Error; Handle it!
        }
    }
}


- (BOOL) canSafelyDelete {
    return (_vaoTotalUseCount == 0);
}


- (NSUInteger) purgeUnusedData {
    
    NSUInteger purgeCount = 0;
    
    NSArray* allKeys = [_vaoDatabase allKeys];
    
    for (NSString* key in allKeys) {
        
        NSMutableDictionary* entry    = [_vaoDatabase objectForKey:key];
        NSInteger            useCount = [[entry objectForKey:kDNRTextureAtlasUseCountKey] integerValue];
        
        if (useCount < 1) {
            // Unused; purge:
            
            // 1. Delete OpenGL ES object
            GLuint vao = [[entry objectForKey:kDNRTextureAtlasVAOKey] unsignedIntValue];
            //glDeleteVertexArraysOES(1, &vao);
            glDeleteVertexArrays(1, &vao);
            
            GLuint vbo = [[entry objectForKey:kDNRTextureAtlasVBOKey] unsignedIntValue];
            glDeleteBuffers(1, &vbo);
            
            
            // 2. Delete database entry
            [_vaoDatabase removeObjectForKey:key];
            
            
            // 3. Method reports how many entries
            //    were actually deleted:
            purgeCount++;
        }
    }
    
    return purgeCount;
}


- (NSString *)dictionaryKeyForSubimageNames:(NSArray *)names {
    /* 
     Generates a key to store (cache) the vertex array object associated with a 
     specific set of subimage names (frames). The concatenation of all subimage 
     names should guarantee uniqueness for a given set, but it risks becoming 
     too long (hence the MD5 hashing)
     */
    
    
    // Sort name array to ensure that different permutations of the same set of
    //  names don't yield different keys:
    NSArray* sortedNames = [names sortedArrayUsingComparator:^ NSComparisonResult (NSString* obj1, NSString* obj2){
        return [obj1 compare:obj2];
    }];
    
    
    // Concatenate all strings into one, to serve as input to the hash function:
    NSMutableString* longString = [NSMutableString new];
    
    for (NSString* name in sortedNames) {
        [longString appendString:name];
    }
    
    // Convert concatenated string to char array (C string):
    const char* cstr = [longString UTF8String];
    
    // Hash it:
    unsigned char result[16];
    unsigned int length = (unsigned int) strlen(cstr);

    CC_MD5(cstr, length, result);
    
    // convert back to NSString:
    NSString* key =[NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
                    result[0],
                    result[1],
                    result[2],
                    result[3],
                    result[4],
                    result[5],
                    result[6],
                    result[7],
                    result[8],
                    result[9],
                    result[10],
                    result[11],
                    result[12],
                    result[13],
                    result[14],
                    result[15]];
    
    // Done:
    return key;
}


- (GLuint) vertexArrayObjectForSubimageNames:(NSArray *)subimageNames {
    /* 
     Returns the (cached) vertex array object associated with a given set of
     image names (frames). It creates it the first time, and returns the 
     existing object the second time on. Single-frame sprites are handled as a 
     special case in which the array contains only one subimage name.
     */
    
    // Calcualte the dictionary key associated with the image name set:
    NSString* key = [self dictionaryKeyForSubimageNames:subimageNames];
    
    NSMutableDictionary* entry = [_vaoDatabase objectForKey:key];
    
    if (entry) {
        // [ A ] Already cached: Increase use count.
        
        NSUInteger vaoUseCount = [[entry objectForKey:kDNRTextureAtlasUseCountKey] unsignedIntegerValue];
        vaoUseCount++;
        [entry setObject:@(vaoUseCount) forKey:kDNRTextureAtlasUseCountKey];
        
        _vaoTotalUseCount++;
        
        return [[entry objectForKey:kDNRTextureAtlasVAOKey] unsignedIntValue];
    }
    else{
        // [ B ] Non-existing; create (and cache) it:
        
        entry = [NSMutableDictionary new];
        
        
        // 1. Generate vertex data (position and texture coordinates)
        
        NSUInteger subimageCount = [subimageNames count];
        NSUInteger vertexCount   = 4 * subimageCount;
        
        CGSize imageSize = [_texture size];
        
        VertexData2D* vertices = calloc(sizeof(VertexData2D), vertexCount);
        GLushort*     indices  = calloc(sizeof(  GLushort  ), vertexCount);
        
        for (NSUInteger i = 0; i < subimageCount; i++) {
        
            NSString* subimageName = [subimageNames objectAtIndex:i];
            
            CGRect rectangle = [self rectangleForSubimageNamed:subimageName];
            
            CGFloat subimageWidth  = rectangle.size.width;
            CGFloat subimageHeight = rectangle.size.height;
            
            // 1.1 Calculate texture coordinates
            
            float s0 = (float)(rectangle.origin.x);
            float s1 = s0 + (float)(subimageWidth);
            float t0 = (float)(rectangle.origin.y);
            float t1 = t0 + (float)(subimageHeight);
            
            s0 = (float)(s0 / imageSize.width );
            s1 = (float)(s1 / imageSize.width );
            t0 = (float)(t0 / imageSize.height);
            t1 = (float)(t1 / imageSize.height);
            
            // (TODO: implement rotation, by means of texture coordinate swap)
            
            
            // 1.2 Build origin-centered quad, texture-mapped to the specified
            //      subimage, at the subimage's native size:
            
            CGFloat subimageHalfWidth  = 0.5f * subimageWidth;
            CGFloat subimageHalfHeight = 0.5f * subimageHeight;
            
            NSUInteger indexOfCurrentVertex = 4*i;
            
            
            // Top Left
            indices[indexOfCurrentVertex] = indexOfCurrentVertex;
            
            vertices[indexOfCurrentVertex].position.x  = -subimageHalfWidth;
            vertices[indexOfCurrentVertex].position.y  = +subimageHalfHeight;
            vertices[indexOfCurrentVertex].texCoords.s = s0;
            vertices[indexOfCurrentVertex].texCoords.t = t0;
            indexOfCurrentVertex++;
            
            
            // Bottom Left
            indices[indexOfCurrentVertex] = indexOfCurrentVertex;
            
            vertices[indexOfCurrentVertex].position.x  = -subimageHalfWidth;
            vertices[indexOfCurrentVertex].position.y  = -subimageHalfHeight;
            vertices[indexOfCurrentVertex].texCoords.s = s0;
            vertices[indexOfCurrentVertex].texCoords.t = t1;
            indexOfCurrentVertex++;
            
            // Top Right
            indices[indexOfCurrentVertex] = indexOfCurrentVertex;
            
            vertices[indexOfCurrentVertex].position.x  = +subimageHalfWidth;
            vertices[indexOfCurrentVertex].position.y  = +subimageHalfHeight;
            vertices[indexOfCurrentVertex].texCoords.s = s1;
            vertices[indexOfCurrentVertex].texCoords.t = t0;
            indexOfCurrentVertex++;
            
            // Bottom Right
            indices[indexOfCurrentVertex] = indexOfCurrentVertex;
            
            vertices[indexOfCurrentVertex].position.x  = +subimageHalfWidth;
            vertices[indexOfCurrentVertex].position.y  = -subimageHalfHeight;
            vertices[indexOfCurrentVertex].texCoords.s = s1;
            vertices[indexOfCurrentVertex].texCoords.t = t1;
            indexOfCurrentVertex++;
            
            // (no scaling needed to render each sprite frame at native size)
        }
        
        
        // (This is how far we can get in the background thread/context. Vertex
        //  Array Objects can not be shared between OpenGL contexts, so we must
        //  create them on the same context they will be drawn in: the main one)
        
        
        // . .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .
        // 2. Create Vertex Array Object on main thread
        
        
        GLuint __block vao = 0;
        
        void (^task)(void) = ^(void){
            // *!* MUST RUN ON MAIN THREAD *!*
            
            GLuint program = [[DNRShaderManager defaultManager] spriteProgram];
            useProgram(program);
            
            GLint positionLocation = glGetAttribLocation(program, "Position");
            GLint texCoordLocation = glGetAttribLocation(program, "TextureCoord");
            
            GLuint vbo = 0;
            GLuint ibo = 0;
            
            
            // VAO
            glGenVertexArrays(1, &vao);
            bindVertexArrayObject(vao);
            
            // VBO
            glGenBuffers(1, &vbo);
            bindVertexBufferObject(vbo);
            glBufferData(GL_ARRAY_BUFFER,
                         vertexCount*sizeof(VertexData2D),
                         &vertices[0],
                         GL_STATIC_DRAW);
            // IBO
            glGenBuffers(1, &ibo);
            bindIndexBufferObject(ibo);
            glBufferData(GL_ELEMENT_ARRAY_BUFFER,
                         vertexCount*sizeof(GLushort),
                         &indices[0],
                         GL_STATIC_DRAW);
            
            
            glEnableVertexAttribArray(positionLocation);
            glEnableVertexAttribArray(texCoordLocation);
            
            glVertexAttribPointer(positionLocation, 2, GL_FLOAT, GL_FALSE, stride2D, positionOffset2D);
            glVertexAttribPointer(texCoordLocation, 2, GL_FLOAT, GL_FALSE, stride2D, textureOffset2D);
            
            bindVertexArrayObject(0);
            
            glDisableVertexAttribArray(positionLocation);
            glDisableVertexAttribArray(texCoordLocation);
            
            bindIndexBufferObject(0);
            bindVertexBufferObject(0);
            
            
            entry[kDNRTextureAtlasVAOKey] = @(vao);
            entry[kDNRTextureAtlasVBOKey] = @(vbo);
            entry[kDNRTextureAtlasIBOKey] = @(ibo);
            entry[kDNRTextureAtlasUseCountKey] = @(1);
            // (0 means "can safely delete when memory is scarce")
            
            free(vertices);
            free(indices);
            
            
            // Store the entry into the dictionary (database)
            [self.vaoDatabase setObject:entry forKey:key];
            
        };
        
        
        if ([NSThread isMainThread]) {
            // . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
            // [ A ] We are already on the main thread/OpenGL context;
            //   go ahead:
            
            task();
            
            return vao;
        }
        else{
            // . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
            // [ B ] We are on a background thread/OpenGL context;
            //   enqueue task in main thread's queue and notify on completion:
            
            dispatch_async( dispatch_get_main_queue(), ^{
                // (Main Thread)
                
                task();
                
                [[NSNotificationCenter defaultCenter] postNotificationName:DNRAtlasLoadedVertexArrayObjectNotification
                                                                    object:self
                                                                  userInfo:@{kDNRAtlasLoadedVertexArrayObjectSumbimageNamesKey : subimageNames}];
            });
            
            // 0 signals the caller to listen to the above notification:
            return 0;
        }
    }
}


@end


//#endif
