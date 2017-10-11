//
//  DNRPointerInput.h
//  DinnerJacket
//
//  Created by Nicolás Fernando Miari on 2016/10/14.
//  Copyright © 2016 Nicolás Miari. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@class DNRNode;


typedef NS_ENUM(NSUInteger, DNRPointInputPhase) {
    /// Corresponds to TouchesBegan/MouseDown
    DNRPointInputPhaseBegan,
    
    /// Corresponds to TouchesMoved/MouseDragged
    DNRPointInputPhaseMoved,
    
    /// Corresponds to TouchesEnded/MouseUp
    DNRPointInputPhaseEnded,
    
    /// Corresponds to TouchesCancelled
    DNRPointInputPhaseCancelled,
    
    DNRPointInputPhaseMax
};


@interface DNRPointerInput : NSObject

/// Location, in world coordinates (OpenGL/OpenGL ES).
@property (nonatomic, readonly) CGPoint location;

///
@property (nonatomic, readonly) NSTimeInterval timestamp;

///
@property (nonatomic, readonly) DNRPointInputPhase phase;


- (instancetype) initWithPhase:(DNRPointInputPhase) phase
                    atLocation:(CGPoint) location
                    timestamp:(NSTimeInterval) timestamp;

+ (instancetype) inputWithPhase:(DNRPointInputPhase) phase
                     atLocation:(CGPoint) location
                 timestamp:(NSTimeInterval) timestamp;

@end
