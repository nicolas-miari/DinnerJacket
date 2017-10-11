//
//  DNRSceneController.h
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-05-03.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import "DNRSceneTransition.h"

#import "Types.h"

extern NSString* const SceneDidTickNotification;

@class DNRScene;


/**
 Manages scene transitions. View and drawinf are managed by the view controller.
 */
@interface DNRSceneController : NSObject


/// Default color used in glClear(). TODO: Rename to "background color".
@property (nonatomic, readwrite) Color4f clearColor;


/// The top node of the current scene
@property (nonatomic, readonly) DNRNode* displayRootNode;


///
@property (nonatomic, readwrite) DNRSceneTransitionType defaultTransitionType;


///
@property (nonatomic, readwrite) CFTimeInterval defaultTransitionDuration;


///
@property (nonatomic, readwrite) DNREasingType  defaultTransitionEasingType;


///



/** 
 Singleton handle
 */
+ (instancetype) defaultController;


/**
 */
- (void) runScene:(DNRScene *)nextScene;


/** 
 */
- (void) tick:(CFTimeInterval) dt;


/** 
 */
- (void) transitionToScene:(DNRScene *)nextScene
                  withType:(DNRSceneTransitionType) transitionType
                  duration:(CFTimeInterval) duration
                easingType:(DNREasingType) easingType;


/** 
 Calls -transitionToScene:withType:duration:easingType: using preset defaults 
 for all arguments except nextScene. Typically, you would set application-wide 
 settings and have all transitions be consistent. Also, it saves typing.
 */
- (void) transitionToScene:(DNRScene *)nextScene;

@end


