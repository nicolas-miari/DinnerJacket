//
//  DNRSceneTransition.m
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-03-08.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import "DNRSceneTransition.h"

#import "DNRScene.h"
#import "DNRSceneController.h"
#import "DNRGLCache.h"

#import "DNRRenderer.h"


@interface DNRSceneTransition ()

@property (nonatomic, readwrite)DNREasingType easingType;


@end


// .............................................................................

@implementation DNRSceneTransition {

    
    float (*_easingFunction)(float t);
    
    CGFloat                     _progressTime;  // [s]
    
    BOOL                        _initialized;
    
    Color4f                     _backgroundClearColor;
}


#pragma mark - Designated Initializers

/**
 Scene 1 and Scene 2 are added as children so that they get frame updates 
 during the transition (otherwise they are dettached form the display tree).
 but we also need to perform custom drawing of them, so return YES to prevent
 both scenes from drawing themselves as they would normally do.
 */
- (BOOL) drawsDescendants {
    return YES;
}

- (id) initWithType:(DNRSceneTransitionType) type
        sourceScene:(DNRScene *)scene1
   destinationScene:(DNRScene *)scene2
           duration:(CGFloat) duration
         easingType:(DNREasingType) easingType; {

    if ((self = [super init])) {
        
        _type         = type;
        
        _scene1       = scene1;
        _scene2       = scene2;
        
        _duration     = duration;
        
        _easingType   = easingType;
        
        /*
         In order for motion updates to continue during the transition, both
         scenes must remain attached to the display tree all the way up to the 
         root (i.e., this transition node), so the easiest way to achieve that
         is to have them as children. 
         But this would trigger both scenes drawing their contents as usual,
         which would interfere with the drawing of the transition. To prevent 
         that, this class overrides -[NDRNode drawsDescendants] to return YES.
         The child scenes get updated, but not drawn.
         */
        [self addChild:_scene1];
        [self addChild:_scene2];
        
        
        switch (_easingType) {
            default:
                
            case DNREaseLinear:
                _easingFunction = LinearInterpolation;
                break;
                
            case DNREaseIn:
                _easingFunction = QuadraticEaseIn;      // TODO: Settle for a default (quad, cubic, etc.)
                break;
                
            case DNREaseOut:
                _easingFunction = QuadraticEaseOut;     // TODO: Settle for a default (quad, cubic, etc.)
                break;
                
            case DNREaseInOut:
                _easingFunction = QuadraticEaseInOut;   // TODO: Settle for a default (quad, cubic, etc.)
                break;
        }
        
        _progressTime = 0.0f;
        
        _backgroundClearColor = [[DNRSceneController defaultController] clearColor];
    }
    
    return self;
}

- (void) dealloc{
    
}


#pragma mark - Specific Initializers


- (id) initWithType:(DNRSceneTransitionType) type
        sourceScene:(DNRScene *)scene1
   destinationScene:(DNRScene *)scene2
           duration:(CGFloat) duration {

    // Default to Linear Easing
    
    return [self initWithType:type
                  sourceScene:scene1
             destinationScene:scene2
                     duration:duration
                   easingType:DNREaseLinear];
}


- (id) initWithType:(DNRSceneTransitionType) type
        sourceScene:(DNRScene *)scene1
   destinationScene:(DNRScene *)scene2
         easingType:(DNREasingType) easingType {

    // Default to 1 second duration
    
    return [self initWithType:type
                  sourceScene:scene1
             destinationScene:scene2
                     duration:1.0
                   easingType:DNREaseLinear];
}


- (id) initWithType:(DNRSceneTransitionType) type
        sourceScene:(DNRScene *)scene1
   destinationScene:(DNRScene *)scene2 {

    // Default to 1 second duration, linear easing
    
    return [self initWithType:type
                  sourceScene:scene1
             destinationScene:scene2
                     duration:1.0];
}


- (id) initCrossDisolveWithSourceScene:(DNRScene *)scene1
                      destinationScene:(DNRScene *)scene2
                              duration:(CGFloat) duration
                            easingType:(DNREasingType) easingType {

    return [self initWithType:DNRSceneTransitionTypeCrossDisolve
                  sourceScene:scene1
             destinationScene:scene2
                     duration:duration
                   easingType:easingType];
}


- (id) initCrossDisolveWithSourceScene:(DNRScene *)scene1
                      destinationScene:(DNRScene *)scene2
                              duration:(CGFloat) duration {

    // Defaults to Linear easing
    
    return [self initWithType:DNRSceneTransitionTypeCrossDisolve
                  sourceScene:scene1
             destinationScene:scene2
                     duration:duration];
}


- (id) initCrossDisolveWithSourceScene:(DNRScene *)scene1
                      destinationScene:(DNRScene *)scene2
                            easingType:(DNREasingType) easingType; {

    // Defaults to 1.0 duration
    
    return [self initWithType:DNRSceneTransitionTypeCrossDisolve
                  sourceScene:scene1
             destinationScene:scene2
                   easingType:easingType];
}


- (id) initCrossDisolveWithSourceScene:(DNRScene *)scene1
                      destinationScene:(DNRScene *)scene2; {

    // Defaults to 1.0 duration and Linear easing
    
    return [self initWithType:DNRSceneTransitionTypeCrossDisolve
                  sourceScene:scene1
             destinationScene:scene2];
}


- (CGFloat) progress {

    // Ratio of completion (ideally, 0.0 to 1.0)
    
    if (_easingFunction) {
        return _easingFunction(_progressTime / _duration);
    }
    else{
        // Linear
        return (_progressTime / _duration);
    }
    // TODO: clip to 1.0?
}


- (DNRScene *)currentScene {
    // "Round" to the closest scene:
    return ([self progress] < 0.5) ? _scene1 : _scene2;
}


- (BOOL) sceneIsVisible:(DNRScene *)scene {

    if (_type == DNRSceneTransitionTypeSequentialFade) {
        
        if ((scene == _scene1) && (_progressTime <= 0.5*_duration)) {
            return YES;
        }
        
        if ((scene == _scene2) && (_progressTime >= 0.5*_duration)) {
            return YES;
        }
        
        return NO;
    }
    else if(_type == DNRSceneTransitionTypeCrossDisolve){
        // Both scenes are visible all along
        
        return ((scene == _scene1) || (scene == _scene2));
    }
    
    return NO;
}


- (BOOL) isComplete {
    return (_progressTime >= _duration);
}


- (BOOL) isTransition {
    return YES;
}


- (void) update:(CFTimeInterval) dt {

    CGFloat oldProgressTime = _progressTime;
    
    _progressTime += dt;
    
    
    [_scene1 update:dt];
    [_scene2 update:dt];
    
    if ((oldProgressTime == 0.0) && (_progressTime > 0.0)) {
        // First update call; Notify:
        
        [[NSNotificationCenter defaultCenter] postNotificationName:DNRSceneTransitionBeganNotification
                                                            object:self];
    }
    
    
    // TEST
    if ((oldProgressTime < 0.5f*_duration) && (_progressTime >= 0.5f*_duration)){
        
    }
    // TEST
    
    CGFloat halfDuration = 0.5f * _duration;
    
    if ((oldProgressTime < halfDuration) && (_progressTime >= halfDuration)) {
        // Crossed mid-point; Notify:
        
        [[NSNotificationCenter defaultCenter] postNotificationName:DNRSceneTransitionProgressedBeyondMidpointNotification
                                                            object:self];
    }
    
    
    if (_progressTime >= _duration) {
        // Finished
        
        [[NSNotificationCenter defaultCenter] postNotificationName:DNRSceneTransitionComletedNotification
                                                            object:self];
    }
}


- (void) draw {

    // TODO: Use selectors and avoid the if statement every frame!
    
    if (_type == DNRSceneTransitionTypeSequentialFade) {
        
        [self drawSequentialFade];
    }
    else if(_type == DNRSceneTransitionTypeCrossDisolve){

        [self drawCrossDissolve];
    }
    else{
        // TODO: Add more transition types
    }
}


- (void) drawSequentialFade {
    
    id<DNRRenderer> renderer = [self renderer];
    
    if (!_initialized) {
        [renderer initializeSequentialFade];
        _initialized = YES;
    }
    
    // Calculate progress
    
    DNRScene* targetScene = nil;
    GLfloat   alpha       = 0.0f;
    
    CGFloat ratio = [self progress];
    
    if (ratio <= 0.5f) {    // Scene #1 Fade out
        targetScene = _scene1;
        alpha       = 1.0 - (2*ratio);
    }
    else{                   // Scene #2 Fade in
        targetScene = _scene2;
        alpha       = (2*ratio) - 1.0;
    }
    
    // TODO: Implement easing
    
    
    [renderer setSceneClearColor:[targetScene clearColor]];
    
    [renderer beginSequentialFadeFrame];
    // (Binds render-to-texture frambuffer and clears screen to scene color)
    
    
    [targetScene drawNodes];
    // (Draws scene's contents)
    
    
    [renderer blendSequentialFadePassWithOpacity:alpha];
    // (Blends scene texture to screen at the specified opacity)
}


- (void) drawCrossDissolve {
    
    id<DNRRenderer> renderer = [self renderer];
    
    [renderer setSceneClearColor:[_scene1 clearColor]];
    [renderer beginCrossDissolveFramePass1];
    
    [_scene1 drawNodes];
    
    [renderer setSceneClearColor:[_scene2 clearColor]];
    [renderer beginCrossDissolveFramePass2];
    
    [_scene2 drawNodes];
    
    [renderer blendCrossDissolvePassesWithProgress:[self progress]];
}



@end
