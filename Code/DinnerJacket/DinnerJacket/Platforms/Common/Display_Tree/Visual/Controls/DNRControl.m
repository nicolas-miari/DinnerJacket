//
//  DNRControl.m
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-08-02.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import "DNRControl.h"

#import "DNRSprite.h"

#import "DNRTargetActionPair.h"

#import "DNRPointerInput.h"


#ifdef DNRPlatformPhone
#import "DNROpenGLESView.h"
#else
#endif

@interface DNRControl ()

/// Defaults to same as highlightedSprite.
@property (nonatomic, strong, readwrite) DNRSprite *selectedSprite;

/// Defaults to same as normalSprite, but with half opacity.
@property (nonatomic, strong, readwrite) DNRSprite *disabledSprite;

/// The sprite for the current state.
@property (nonatomic, weak, readwrite) DNRSprite *activeSprite;

@end


@implementation DNRControl {
    
    NSMutableArray* _targetInfos;
    
    BOOL            _touchInside;
    CGPoint         _previousTouchLocation;
}


- (instancetype) initWithNormalSprite:(DNRSprite *)normalSprite
                    highlightedSprite:(DNRSprite *)highlightedSprite {

    if (self = [super init]) {
        
        _normalSprite      = normalSprite;
        _highlightedSprite = highlightedSprite;
        
        [self addChild:_normalSprite];
        _state = DNRControlStateNormal;
        _activeSprite = _normalSprite;
        
        // Prevent children from blocking touch events aimed at this control:
        [_normalSprite setUserInteractionEnabled:NO];
        [_highlightedSprite setUserInteractionEnabled:NO];
        
        
        _targetInfos = [NSMutableArray new];
    }
    
    return self;
}


- (void) dealloc {
    [self removeAllTargets];
}


- (DNRSprite *)spriteForState:(DNRControlState) state {

    switch (_state) {
    
        case DNRControlStateNormal:
            [_normalSprite setAlpha:1.0f];
            [_normalSprite setColorBlendFactor:0.0f];
            
            return _normalSprite;
            break;
            
        
        case DNRControlStateHighlighted:
            // Has a dedicated HIGHLIGHTED state sprite?
            
            if (_highlightedSprite) {
                
                // YES - use it
                
                return _highlightedSprite;
            }
            else{
                // NO - Default to normal sprite, 50% black tint
                
                [_normalSprite setAlpha:1.0f];
                [_normalSprite setColorBlendFactor:0.5f];
                [_normalSprite setTintColor:Color4fBlack];
                
                return _normalSprite;
            }
            break;
            
            
        case DNRControlStateSelected:
            // Has a dedicated SELECTED state sprite?
            if (_selectedSprite) {
                
                // YES - use it
                
                return _selectedSprite;
            }
            else{
                // NO - Default to highlighted sprite
                
                return [self spriteForState:DNRControlStateHighlighted];
            }
            break;
            
            
        case DNRControlStateDisabled:
            // Has a dedicated DISABLED state sprite?
            if (_disabledSprite) {
                
                // YES - use it
                return _disabledSprite;
            }
            else{
                // NO - Default to normal sprite, 50% opacity
                
                [_normalSprite setColorBlendFactor:0.0f];
                [_normalSprite setAlpha:0.5f];
                
                return _normalSprite;
            }
            break;
            
        default:
            break;
    }
    
    return nil;
}


- (void) setState:(DNRControlState) state {

    if (state != _state) {
        
        _state = state;
        
        [self removeAllChildren];
        
        _activeSprite = [self spriteForState:_state];
        
        [self addChild:_activeSprite];
    }
}


- (DNRControlState) stateAfterTouchEnded {

    // Default behaviour for e.g. buttons. A switch subclass can override and
    // instead toggle between DNRControlStateNormal and DNRControlStateSelected.
    
    return DNRControlStateNormal;
}


- (DNRControlState) stateDuringDragOutside {

    // Default behaviour for e.g. buttons. A switch subclass can override and
    // instead return either DNRControlStateNormal or DNRControlStateSelected,
    // depending on which one was active when the touch began.
    
    return DNRControlStateNormal;
}


- (BOOL) swallowsTouches {
    /* 
     A Control swallows and claims touches. The actual hit test is always
     performed on the child node that is active at the moment (e.g., normal
     state sprite)
     */
    return YES;
}


- (BOOL) isUserInteractionEnabled {
    return (_state != DNRControlStateDisabled);
}


- (BOOL) pointInGlobalCoordinatesIsWithinBounds:(CGPoint) globalPoint
                                  withTolerance:(CGFloat) tolerance {
    // Defer to currently active sprite:
    return [_activeSprite pointInGlobalCoordinatesIsWithinBounds:globalPoint
                                                   withTolerance:0.0f];
}


- (void) addTarget:(id) target
            action:(SEL) action
  forControlEvents:(DNRControlEvents) controlEvents; {

    // Search
    for (DNRTargetActionPair* pair in _targetInfos) {
        
        if ([pair target] == target) {
            // Same target
            
            if ([pair events] == controlEvents) {
                // exact same events
                
                if ([pair action] == action) {
                    // exact same action
                    
                    return;
                }
            }
        }
    }
    
    DNRTargetActionPair* newPair = [[DNRTargetActionPair alloc] initWithTarget:target
                                                                        action:action
                                                                 controlEvents:controlEvents];
    [_targetInfos addObject:newPair];
}


- (void) removeTarget:(id) target
     forControlEvents:(DNRControlEvents) controlEvents {

    NSMutableArray* pairsToRemove = [NSMutableArray new];
    
    // Search
    for (DNRTargetActionPair* pair in _targetInfos) {
        
        if ([pair target] == target) {
            // Same target
            
            if ([pair events] == controlEvents) {
                // exact same events
                
                [pairsToRemove addObject:pair];
            }
        }
    }
    
    [_targetInfos removeObjectsInArray:pairsToRemove];
}


- (void) removeTarget:(id) target {

    NSMutableArray* pairsToRemove = [NSMutableArray new];
    
    // Search
    for (DNRTargetActionPair* pair in _targetInfos) {
        
        if ([pair target] == target) {
            // Same target
            
            [pairsToRemove addObject:pair];
        }
    }
    
    [_targetInfos removeObjectsInArray:pairsToRemove];
}


- (void) removeAllTargets {

    [_targetInfos removeAllObjects];
}


- (BOOL) inputBegan:(DNRPointerInput *)input {
    
    if(_state == DNRControlStateHighlighted){
        // Already highlighted; ignore
        return NO;
    }
    
    [self setState:DNRControlStateHighlighted];
    
    _touchInside = YES;
    
    [self touchDown];
    
    return YES;
}


- (void) inputMoved:(DNRPointerInput *)input {

    CGPoint location = input.location;
    
    // See if touch is within active sprite's bounds
    
    if (_touchInside) {
        // Was Inside...
        
        if ([_activeSprite pointInGlobalCoordinatesIsWithinBounds:location withTolerance:0.0f]) {
            // ...Still Inside:
            [self dragInside];
        }
        else{
            // ...Now Outside:
            [self dragExit];
            [self setState:[self stateDuringDragOutside]];
            _touchInside = NO;
        }
    }
    else{
        // Was Outside...
        
        if ([_activeSprite pointInGlobalCoordinatesIsWithinBounds:location withTolerance:0.0f]) {
            // ...Now Inside:
            [self dragEnter];
            [self setState:DNRControlStateHighlighted];
            _touchInside = YES;
        }
        else{
            // ...Still Outside:
            [self dragOutside];
        }
    }
    
    _previousTouchLocation = location;
}


- (void) inputEnded:(DNRPointerInput *)input  {

    if ([_activeSprite pointInGlobalCoordinatesIsWithinBounds:[input location] withTolerance:0.0f]) {
        [self touchUpInside];
    }
    else{
        [self touchUpOutside];
    }
    
    [self setState:[self stateAfterTouchEnded]];
}


- (void) inputCancelled:(DNRPointerInput *)input  {

    [self inputEnded:input];
}


- (void) touchDown {

    for (DNRTargetActionPair* pair in _targetInfos) {
        
        if ([pair events] & DNRControlEventTouchDown ) {
            
            [pair trigger:self];
        }
    }
}


- (void) dragInside {

    for (DNRTargetActionPair* pair in _targetInfos) {
        
        if ([pair events] & DNRControlEventTouchDragInside ) {
            
            [pair trigger:self];
        }
    }
}


- (void) dragExit {

    for (DNRTargetActionPair* pair in _targetInfos) {
        
        if ([pair events] & DNRControlEventTouchDragExit ) {
            
            [pair trigger:self];
        }
    }
}


- (void) dragOutside {

    for (DNRTargetActionPair* pair in _targetInfos) {
        
        if ([pair events] & DNRControlEventTouchDragOutside ) {
            
            [pair trigger:self];
        }
    }
}


- (void) touchUpOutside {

    for (DNRTargetActionPair* pair in _targetInfos) {
        
        if ([pair events] & DNRControlEventTouchUpOutside ) {
            
            [pair trigger:self];
        }
    }
}


- (void) dragEnter {

    for (DNRTargetActionPair* pair in _targetInfos) {
        
        if ([pair events] & DNRControlEventTouchDragEnter) {
            
            [pair trigger:self];
        }
    }
}


- (void) touchUpInside {

    for (DNRTargetActionPair* pair in _targetInfos) {
        
        if ([pair events] & DNRControlEventTouchUpInside ) {
            
            [pair trigger:self];
        }
    }
}


@end
