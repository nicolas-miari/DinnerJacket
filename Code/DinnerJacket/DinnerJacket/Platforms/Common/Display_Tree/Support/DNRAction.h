//
//  DNRAction.h
//  Toutoulina
//
//  Created by Nicolás Miari on 2014-08-13.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OpenGL.h"

#import <CoreGraphics/CoreGraphics.h>

#import "DNREasingFunctions.h"



@class DNRNode;


/**
 Represents a progressive (i.e., animated) action that can be performed on a 
 node.
 */
@interface DNRAction : NSObject

/// The node that is affected by the action.
@property (nonatomic, weak, readwrite) DNRNode* target;

/// The type of easing used.
@property (nonatomic, readwrite)DNREasingType  easingType;

/// Whether the action has completed or not.
@property (nonatomic, readonly, getter=isComplete) BOOL complete;


/**
 Empty action. The node is not affected, but another action can be chained upon
 its completion.
 */
+ (instancetype) waitForSeconds:(CFTimeInterval) seconds
                     completion:(void(^)(void)) completion;

/**
 */
+ (instancetype) fadeToAlpha:(GLfloat) alpha
                withDuration:(CFTimeInterval) duration
                  completion:(void (^)(void)) completion;

/**
 */
+ (instancetype) moveTo:(CGPoint) destination
           withDuration:(CFTimeInterval) duration
             completion:(void (^)(void)) completion;

/**
 */
+ (instancetype) moveBy:(CGVector) distanceToTravel
           withDuration:(CFTimeInterval) duration
             completion:(void (^)(void)) completion;

/**
 */
- (void) update:(CFTimeInterval) dt;

@end
