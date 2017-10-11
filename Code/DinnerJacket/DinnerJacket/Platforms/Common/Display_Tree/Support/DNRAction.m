//
//  DNRAction.m
//  Toutoulina
//
//  Created by Nicolás Miari on 2014-08-13.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import "DNRAction.h"

#import "DNRNode.h"



typedef NS_ENUM(NSUInteger, DNRActionType) {
    
    DNRActionTypeWait,
    DNRActionTypeAlpha,
    DNRActionTypePosition,
    
    DNRActionTypeMax
};


#pragma mark - Base Class (Private Interface)

// Private interface - makes ivars available to private subclasses

@interface DNRAction() {

@protected
    
    DNRActionType       _type;
    
   DNREasingType       _easingType;
    
    DNREasingFunction   _easingFunction;
    
    SEL                 _selector;
    
    DNRNode* __weak     _target;
    
    CFTimeInterval      _timeEllapsed;
    
    CFTimeInterval      _duration;
    
    CGFloat             _ratioOfProgress;
    
    
    void (^_completionHandler)(void);
}


// DESIGNATED INITIALIZER
- (instancetype) initWithDuration:(CFTimeInterval) duration
                       completion:(void (^)(void)) completion;


@end


#pragma mark - Wait (Internal Interface)

@interface _DNRWaitAction : DNRAction


@end


#pragma mark - Fade Alpha (Internal Interface)

@interface _DNRFadeAction : DNRAction

- (instancetype) initWithDuration:(CFTimeInterval) duration
                       finalAlpha:(GLfloat) finalAlpha
                       completion:(void (^)(void)) completion;

- (void) applyProgress;

- (void) grabInitialState;

@end



#pragma mark - Move To (Internal Interface)


@interface _DNRMoveToAction : DNRAction

- (instancetype) initWithDuration:(CFTimeInterval)duration
                    finalPosition:(CGPoint) position
                       completion:(void (^)(void))completion;

- (void) applyProgress;

- (void) grabInitialState;

@end


#pragma mark - Move By (Internal Interface)


@interface _DNRMoveByAction : DNRAction

- (instancetype) initWithDuration:(CFTimeInterval)duration
                    deltaPosition:(CGVector) distanceTravelled
                       completion:(void (^)(void))completion;

- (void) applyProgress;

- (void) grabInitialState;

@end


#pragma mark - Base Class (Implementation)


@implementation DNRAction {

    // (All ivars are in private interface)
}

@synthesize target     = _target;
@synthesize easingType = _easingType;


// FACTORIES

+ (instancetype) waitForSeconds:(CFTimeInterval) seconds
                     completion:(void(^)(void)) completion {

    return [[self alloc] initWithDuration:seconds
                               completion:completion];
}


+ (instancetype) fadeToAlpha:(GLfloat) alpha
                withDuration:(CFTimeInterval) duration
                  completion:(void (^)(void)) completion {

    return [[_DNRFadeAction alloc] initWithDuration:duration
                                         finalAlpha:alpha
                                         completion:completion];
}


+ (instancetype) moveTo:(CGPoint) destination
           withDuration:(CFTimeInterval) duration
             completion:(void (^)(void)) completion {

    return [[_DNRMoveToAction alloc] initWithDuration:duration
                                        finalPosition:destination
                                           completion:completion];
}


+ (instancetype) moveBy:(CGVector) distanceToTravel
           withDuration:(CFTimeInterval) duration
             completion:(void (^)(void)) completion {

    return [[_DNRMoveByAction alloc] initWithDuration:duration
                                        deltaPosition:distanceToTravel
                                           completion:completion];
}

// DESIGNATED INITIALIZER

- (instancetype) initWithDuration:(CFTimeInterval) duration
                       completion:(void (^)(void)) completion {

    if (self = [super init]) {
        
        _duration          = duration;
        _completionHandler = completion;
        
        [self setEasingType:DNREaseLinear];
    }
    
    return self;
}


- (void) setTarget:(DNRNode *)target {

    // (Called by target node on -runAction:)
    
    _target = target;
    
    [self grabInitialState];
    // (subclass-dependent)
}


- (void) setEasingType:(DNREasingType)easingType {

    _easingType = easingType;
    
    switch (_easingType) {
            
        case DNREaseLinear:
            _easingFunction = LinearInterpolation;
            break;
            
        case DNREaseIn:
        case DNRQuadraticEaseIn:
            _easingFunction = QuadraticEaseIn;
            break;
            
        case DNREaseOut:
        case DNRQuadraticEaseOut:
            _easingFunction = QuadraticEaseOut;
            break;
            
        case DNREaseInOut:
        case DNRQuadraticEaseInOut:
            _easingFunction = QuadraticEaseInOut;
            break;
            
        case DNRCubicEaseIn:
            _easingFunction = CubicEaseIn;
            break;
            
        case DNRCubicEaseOut:
            _easingFunction = CubicEaseOut;
            break;
            
        case DNRCubicEaseInOut:
            _easingFunction = CubicEaseInOut;
            break;
            
        default:
            break;
    }
}


- (BOOL) isComplete {

    return (_timeEllapsed >= _duration);
}


- (void) grabInitialState {

    // (Base class does nothing)
}


- (void) applyProgress {

    // (Base class does nothing)
}


- (void) update:(CFTimeInterval) dt {

    /* 
     Modify target property by the correct amount
    */
    
    // Target must exist!
    NSAssert(_target, @"Error: Updating target-less action!");
    // TODO: do nothing. log and return?
    
    
    // Update timer
    _timeEllapsed += dt;
    
    
    // Calculate progress percentage based on easing settings:
    _ratioOfProgress = _easingFunction(_timeEllapsed / _duration);
    
    
    // Apply changes
    [self applyProgress];
    // (Subclass-dependent)
    
    
    // Test for completion/notifiy
    if (_timeEllapsed >= _duration) {
        // Finished -
        //  Execute completion handler (if available)
        
        if (_completionHandler) {
            _completionHandler();
        }
    }
}

@end


#pragma mark - Wait (Implementation)

@implementation _DNRWaitAction



@end


#pragma mark - Fade Alpha (Implementation)


@implementation _DNRFadeAction {

    GLfloat _initialAlpha;
    
    GLfloat _finalAlpha;
}


- (instancetype) initWithDuration:(CFTimeInterval) duration
                       finalAlpha:(GLfloat) finalAlpha
                       completion:(void (^)(void)) completion {

    if (self = [super initWithDuration:duration completion:completion]) {
        
        _finalAlpha = finalAlpha;
        
        // (initial alpha is grabbed once target is set)
    }
    
    return self;
}


- (void) grabInitialState {

    _initialAlpha = [_target alpha];
}


- (void) applyProgress {

    // Interpolate
    GLfloat currentAlpha = (_ratioOfProgress*_finalAlpha) + ((1.0f - _ratioOfProgress)*_initialAlpha);
    
    [_target setAlpha:currentAlpha];
}

@end


#pragma mark - Move To (Internal Interface)

@implementation _DNRMoveToAction {

    CGPoint     _initialPosition;
    
    CGPoint     _destination;
}



- (instancetype) initWithDuration:(CFTimeInterval) duration
                    finalPosition:(CGPoint) position
                       completion:(void (^)(void)) completion {

    if (self = [super initWithDuration:duration completion:completion]) {
        
        _destination = position;
    }
    
    return self;
}


- (void) grabInitialState {

    _initialPosition = [_target position];
}


- (void) applyProgress {

    CGFloat inverseRatio = 1.0f - _ratioOfProgress;
    
    CGPoint currentPosition = CGPointZero;
    
    currentPosition.x = (inverseRatio * _initialPosition.x) + (_ratioOfProgress*_destination.x);
    currentPosition.y = (inverseRatio * _initialPosition.y) + (_ratioOfProgress*_destination.y);
    
    [_target setPosition:currentPosition];
}



@end


#pragma mark - Move To (Internal Interface)


@implementation _DNRMoveByAction {

    CGPoint     _initialPosition;
    
    CGVector    _distanceToTravel;
}



- (instancetype) initWithDuration:(CFTimeInterval) duration
                    deltaPosition:(CGVector) distanceToTravel
                       completion:(void (^)(void)) completion {

    if (self = [super initWithDuration:duration completion:completion]) {
        
        _distanceToTravel = distanceToTravel;
    }
    
    return self;
}


- (void) grabInitialState {

    _initialPosition = [_target position];
}


- (void) applyProgress {

    CGPoint currentPosition = CGPointZero;
    
    currentPosition.x = _initialPosition.x + _ratioOfProgress*_distanceToTravel.dx;
    currentPosition.y = _initialPosition.y + _ratioOfProgress*_distanceToTravel.dy;
    
    [_target setPosition:currentPosition];
}


@end


