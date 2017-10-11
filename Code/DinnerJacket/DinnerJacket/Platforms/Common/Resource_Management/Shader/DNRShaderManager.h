//
//  DNRShaderManager.h
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-03-08.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 */
@interface DNRShaderManager : NSObject


/// Renders textured quads (uniform tint color)
@property (nonatomic, readonly) GLuint spriteProgram;


/// Renders textured quads (per-vertex tint color)
@property (nonatomic, readonly) GLuint spriteProgramWithPerVertexColor;


/// Renders textured quads, discards alpha < 0.1
@property (nonatomic, readonly) GLuint spriteProgramWithAlphaTest;


/// Renders flat shaded quads
@property (nonatomic, readonly) GLuint flatProgram;


/**
 Singleton.
 */
+ (instancetype) defaultManager;


/**
 */
- (BOOL) initializeDefaultPrograms;


/**
 */
- (GLuint) programNamed:(NSString *)programName;


/**
 */
- (GLuint) programWithVertexShaderNamed:(NSString *)vertexName
                 andFragmentShaderNamed:(NSString *)fragmentName;


@end
