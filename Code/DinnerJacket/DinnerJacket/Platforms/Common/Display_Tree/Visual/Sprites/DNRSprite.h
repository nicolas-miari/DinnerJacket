//
//  DNRSprite.h
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-05-02.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import "DNRNode.h"

#import "Types.h"

@class DNRTextureAtlas;

@class DNRFrameAnimationSequence;


/** Sprites created in a background thread/OpenGL context do not get ready to be 
    rendered right away: the Vertex Array Object containing the geometry 
    associated with their subimage in the atlas can only be created on the main 
    OpenGL context. When such a sprite finally gets its geometry set, it posts 
    this notification to inform objects that might depend on it (e.g. a 
    "Loading" screen).
 */
extern NSString* const DNRSpriteBecameReadyNotification;



/** 
 */
@interface DNRSprite : DNRNode


/// Sprite's current size (in points)
@property (nonatomic, readwrite) CGSize size;

///
@property (nonatomic, readwrite) CGPoint scale;

///
@property (nonatomic, readwrite) CGFloat xScale;

///
@property (nonatomic, readwrite) CGFloat yScale;

///
@property (nonatomic, readwrite) Color4f tintColor;

///
@property (nonatomic, readwrite) CGFloat  colorBlendFactor;

///
@property (nonatomic, readwrite) DNRFrameAnimationSequence* animationSequence;


// Solid

/** 
 */
- (instancetype) initWithSize:(CGSize) size color:(Color4f)color;


// Textured (single frame)

/**
 */
- (instancetype) initWithSubimageNamed:(NSString *)subimageName
                        inTextureAtlas:(DNRTextureAtlas *)atlas;


// Textured (multiple frames)

/**
 */
- (instancetype) initWithSubimageNames:(NSArray *)subimageNames
                        inTextureAtlas:(DNRTextureAtlas *)atlas;

/**
 */
- (instancetype) initWithAnimationSequenceNamed:(NSString* )scriptName;


/**
 */
- (void) startAnimating;

/**
 */
- (void) startAnimatingWithCompletion:(void(^)(void))completion;


/**
 */
- (void) stopAnimating;

@end

