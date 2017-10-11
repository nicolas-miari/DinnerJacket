//
//  DNRControl.h
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-08-02.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import "DNRNode.h"

#import "DNRControlEvents.h"



typedef NS_ENUM(NSUInteger, DNRControlState) {
    
    DNRControlStateNormal,
    DNRControlStateHighlighted,
    DNRControlStateSelected,
    DNRControlStateDisabled,
    
    DNRControlStateMax
};


@class DNRSprite;


/**
 */
@interface DNRControl : DNRNode

///
@property (nonatomic, readonly) DNRControlState state;

///
@property (nonatomic, readonly) DNRSprite* normalSprite;

/// Defaults to same as normalSprite
@property (nonatomic, readonly) DNRSprite* highlightedSprite;


/**
 */
- (instancetype) initWithNormalSprite:(DNRSprite *)normalSprite
                    highlightedSprite:(DNRSprite *)highlightedSprite;

/**
 */
- (void) setState:(DNRControlState) state;


/**
 */
- (void) touchDown;

/**
 */
- (void) dragInside;

/**
 */
- (void) dragExit;

/**
 */
- (void) dragOutside;

/**
 */
- (void) touchUpOutside;

/**
 */
- (void) dragEnter;

/**
 */
- (void) touchUpInside;

/**
 */
- (void) addTarget:(id) target
            action:(SEL) action
  forControlEvents:(DNRControlEvents) controlEvents;


@end
