//
//  DNRTextureAtlas.h
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-05-02.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>   // CGSize

#import "DNRResourceCommon.h"



@class DNRTexture;
@class DNRTextureAtlas;



extern NSString* const DNRAtlasLoadedVertexArrayObjectNotification;

extern NSString* const kDNRAtlasLoadedVertexArrayObjectSumbimageNamesKey;

/**
    @interface DNRTextureAtlas
 
    @brief 
        Manages a single texture and a database of named subimages within it,
        used to create individual sprites that render more effciently.
 
    @details
        An OpenGL ES vertex array object (VAO) is created lazily for each named
        subimage. different sprite instances of the same subimage share the same
        VAO. All sprite instances, regardless of the subimage, share the same 
        index buffer object (IBO): vertex indices 0, 1, 2, 3.
 
    @since 1.0.0
 */
@interface DNRTextureAtlas : NSObject



///
@property (nonatomic, readonly, getter=isLoaded) BOOL loaded;

///
@property (nonatomic, readonly) DNRTexture* texture;

///
@property (nonatomic, readonly) GLuint      textureName;



/**
 */
+ (DNRTextureAtlas *)atlasNamed:(NSString *)atlasName;


/**
 */
+ (void) loadTextureAtlasNamed:(NSString *)atlasName
                    completion:(DNRResourceLoadingCompletionHandler) completionHandler;


/**
 */
+ (GLuint) sharedQuadIndexBufferObject;


/**
 */
+ (GLuint) sharedMeshIndexBufferObject;



/**
 */
+ (void) purgeUnusedAtlases;


/**
 */
- (BOOL) subimageIsOpaque:(NSString *)subimageName;

/**
 */
- (CGSize) sizeForSubimageNamed:(NSString *)subimageName;


/**
 */
- (GLuint) vertexArrayObjectForSubimageNames:(NSArray *)subimageNames;

/**
 */
- (void) relinquishVertexArrayObjectForSubimageNames:(NSArray *)subimageNames;

/**
 */
- (BOOL) canSafelyDelete;


@end

