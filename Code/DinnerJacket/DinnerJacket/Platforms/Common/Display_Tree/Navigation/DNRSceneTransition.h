//
//  DNRSceneTransition.h
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-03-08.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import "DNRNavigationNode.h"

#import "DNREasingFunctions.h"


/** 
 In addition to registered listeners being notified as per the
 <DNRSceneTransitionObserver> protocol, transition instances also broadcast
 important events through NSNotificationCenter:
 */
#define DNRSceneTransitionBeganNotification                           @"SceneTransitionBegan"
#define DNRSceneTransitionProgressedBeyondMidpointNotification        @"ProgressedBeyondMidpoint"
#define DNRSceneTransitionComletedNotification                        @"SceneTransitionCompleted"


@class DNRScene;


/**
 */
typedef enum tDNRSceneTransitionType {

    DNRSceneTransitionTypeSequentialFade = 0,
    DNRSceneTransitionTypeCrossDisolve,
    
    // Consider adding more...
    
    DNRSceneTransitionTypeMax
    
}DNRSceneTransitionType;


/**
 Manages the gradual transition between to scenes.
 */
@interface DNRSceneTransition : DNRNavigationNode


/// The type of transition. See `DNRSceneTransitionType` for a list of possible
/// values.
@property (nonatomic, readonly) DNRSceneTransitionType  type;


/// The starting scene of the transition.
@property (nonatomic, readonly) DNRScene *scene1;


/// The finishing scene of the transition.
@property (nonatomic, readonly) DNRScene *scene2;


/// The total duration of the transition, in seconds.
@property (nonatomic, readonly) CGFloat duration;


/// The proportion of progress, taking easing into account. That is, if the
/// duration is 1.0 and easing is not linear, after 0.25 seconds this value will
/// not be 0.25.
@property (nonatomic, readonly) CGFloat progress;


/// Completion flag.
@property (nonatomic, readonly, getter = isComplete) BOOL complete;



/** 
 Designated Initializer.
 */
- (id) initWithType:(DNRSceneTransitionType) type
        sourceScene:(DNRScene *)scene1
   destinationScene:(DNRScene *)scene2
           duration:(CGFloat) duration
         easingType:(DNREasingType) easingType;


// Shortcut Initializers (Extensive):

/** 
 Defaults `easingType` to `DNRSceneTransitionEasingTypeLinear`.
 */
- (id) initWithType:(DNRSceneTransitionType) type
        sourceScene:(DNRScene *)scene1
   destinationScene:(DNRScene *)scene2
           duration:(CGFloat) duration;

/** 
 Defaults duration to 1.0
 */
- (id) initWithType:(DNRSceneTransitionType) type
        sourceScene:(DNRScene *)scene1
   destinationScene:(DNRScene *)scene2
         easingType:(DNREasingType) easingType;

/**
 Defaults `easingType` to `DNRSceneTransitionEasingTypeLinear` and `duration` to 
 `1.0`.
 */
- (id) initWithType:(DNRSceneTransitionType) type
        sourceScene:(DNRScene *)scene1
   destinationScene:(DNRScene *)scene2;


/** 
 Specifies `DNRSceneTransitionTypeCrossDisolve`.
 */
- (id) initCrossDisolveWithSourceScene:(DNRScene *)scene1
                      destinationScene:(DNRScene *)scene2
                              duration:(CGFloat) duration
                            easingType:(DNREasingType) easingType;

/**
 Specifies `DNRSceneTransitionTypeCrossDisolve` and defaults `easingType` to
 `DNRSceneTransitionEasingTypeLinear`.
 */
- (id) initCrossDisolveWithSourceScene:(DNRScene *)scene1
                      destinationScene:(DNRScene *)scene2
                              duration:(CGFloat) duration;

/** 
 Specifies `DNRSceneTransitionTypeCrossDisolve` and defaults `duration` to 
 `1.0`.
 */
- (id) initCrossDisolveWithSourceScene:(DNRScene *)scene1
                      destinationScene:(DNRScene *)scene2
                            easingType:(DNREasingType) easingType;

/** 
 Specifies `DNRSceneTransitionTypeCrossDisolve`, defaults `easingType` to
 `DNRSceneTransitionEasingTypeLinear` and `duration` to `1.0`.
 */
- (id) initCrossDisolveWithSourceScene:(DNRScene *)scene1
                      destinationScene:(DNRScene *)scene2;

/**
 */
- (DNRScene *)currentScene;

/**
 */
- (BOOL) sceneIsVisible:(DNRScene *)scene;

@end

