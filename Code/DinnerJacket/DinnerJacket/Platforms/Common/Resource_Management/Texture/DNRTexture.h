//
//  DNRTexture.h
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-05-03.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import <Foundation/Foundation.h>           // NSObject
#import <CoreGraphics/CoreGraphics.h>       // CGSize
#import "DNRResourceCommon.h"


/**
 Represents an OpenGL texture that can be used to render a sprite or other 
 geometry.
 
 Initializers are private. Instead, use the factory methods that internally 
 enforce resource management (caching of textures already loaded for reuse, 
 purging of unused textires under low memory situations, etc.).
 */
@interface DNRTexture : NSObject


/// OpenGL texture name. For use in conjuction with glBindTexture().
@property (nonatomic, readonly ) GLuint     name;


/// Size, in points. For atlas subregion calculations.
@property (nonatomic, readonly ) CGSize     size;


/// Helps manager determine which textures can be purged (those with a use
/// count of zero).
@property (nonatomic, readwrite) NSInteger  useCount;


/**
 Synchronous loading (returns right away if cached). Set the option
 DNRTextureLoadOptionsOpenGLContext to a custom OpenGL context object to use for
 loading the texture; otherwise the main rendering context is used (This is
 useful to serialize the loading of several textures from within a background
 thread).
 */
+ (DNRTexture*) textureWithContentsOfFile:(NSString *)path
                                  options:(NSDictionary *)options;

/**
 Loading the specified texture asynchronously.
 If the texture was already loaded and cached, the completion handler block is 
 executed right away. Otherwise, the texture is loaded in the background 
 dispatch queue and the completion handler block is executed on completion. In 
 either case, the passed block ALWAYS runs on the main thread.
 To load several textures from within a background thread, use e.g. a for-loop 
 and call: -textureWithContentsOfFile:options: instead, each time passing the 
 background OpenGL context to be used in the options dictionary (by the key 
 DNRTextureLoadOptionsOpenGLContext).
 */
+ (void) loadTextureWithContentsOfFile:(NSString *)path
                               options:(NSDictionary *)options
                            completion:(DNRResourceLoadingCompletionHandler) completionHandler;

/**
 */
+ (void) purgeUnusedTextures;


/** 
 Claims ownership of the receiver. A texture owned by one or more objects will 
 not be deleted during low memory situations.
 */
- (void) aquire;

/** 
 Renounces ownership of the receiver. A texture that is not owned by any object 
 can be dafely deleted during low memory situations.
 A texture may remain in memory indefinitely even if no object references it, as
 long as available system memory is not scarce.
 */
- (void) relinquish;

@end
