//
//  DNRScene.h
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-03-08.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import "DNRNavigationNode.h"       // Super class

#import "DNRSceneController.h"      // To aid use in scene subclasses
#import "DNRSprite.h"               // To aid use in scene subclasses


/**
 Navigation node that represents a regular, static scene (i.e., not a transition
 between scenes).
 */
@interface DNRScene : DNRNavigationNode


/// Returns NO before -[DNRScene didEnter] is sent, YES after.
@property (nonatomic, readonly) BOOL  entered;


/// Scene's clear screen color (background color). It is independent from the
/// scene controller's clear color, so during a sequential fade transition, both
/// clear colors (scene controller and scene) blend accordingly.
@property (nonatomic, readwrite) Color4f  clearColor;


/** 
 Sent before the scene is displayed or starts a transition
 */
- (void) willEnter;


/** 
 Sent after the scene has been added or finished appearing in a transition.
 */
- (void) didEnter;


/** 
 Sent before the receiver is removed from screen, or before a transition out of 
 the receiver begins.
 */
- (void) willExit;


/** 
 Sent after the receiver is removed from screen, or after a transition out of 
 the receiver completes.
 */
- (void) didExit;


/** 
 Sent by scene controller or parent transition every frame, to render display
 hierarchy subtree (descendant nodes).
 */
- (void) drawNodes;

@end


