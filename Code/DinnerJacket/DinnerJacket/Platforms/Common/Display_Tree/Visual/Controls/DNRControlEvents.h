//
//  DNRControlEvents.h
//  DinnerJacket
//
//  Created by Nicolás Fernando Miari on 2016/09/13.
//  Copyright © 2016 Nicolás Miari. All rights reserved.
//

#ifndef DNRControlEvents_h
#define DNRControlEvents_h

#import "Platform.h"

#if defined(DNRPlatformPhone)

#import <UIKit/UIKit.h>

typedef NS_OPTIONS(NSUInteger, DNRControlEvents) {
    
    DNRControlEventTouchDown           = UIControlEventTouchDown,      // on all touch downs
    DNRControlEventTouchDownRepeat     = UIControlEventTouchDownRepeat,      // on multiple touchdowns (tap count > 1)
    DNRControlEventTouchDragInside     = UIControlEventTouchDragInside,
    DNRControlEventTouchDragOutside    = UIControlEventTouchDragOutside,
    DNRControlEventTouchDragEnter      = UIControlEventTouchDragEnter,
    DNRControlEventTouchDragExit       = UIControlEventTouchDragExit,
    DNRControlEventTouchUpInside       = UIControlEventTouchUpInside,
    DNRControlEventTouchUpOutside      = UIControlEventTouchUpOutside,
    DNRControlEventTouchCancel         = UIControlEventTouchCancel,
    /*
    DNRControlEventValueChanged                                      = 1 << 12,     // sliders, etc.
    DNRControlEventPrimaryActionTriggered NS_ENUM_AVAILABLE_IOS(9_0) = 1 << 13,     // semantic action: for buttons, etc.
    
    DNRControlEventEditingDidBegin                                   = 1 << 16,     // UITextField
    DNRControlEventEditingChanged                                    = 1 << 17,
    DNRControlEventEditingDidEnd                                     = 1 << 18,
    DNRControlEventEditingDidEndOnExit                               = 1 << 19,     // 'return key' ending editing
    
    DNRControlEventAllTouchEvents                                    = 0x00000FFF,  // for touch events
    DNRControlEventAllEditingEvents                                  = 0x000F0000,  // for UITextField
    DNRControlEventApplicationReserved                               = 0x0F000000,  // range available for application use
    DNRControlEventSystemReserved                                    = 0xF0000000,  // range reserved for internal framework use
    DNRControlEventAllEvents                                         = 0xFFFFFFFF
     */
};



#elif defined(DNRPlatformMac)

#import <Cocoa/Cocoa.h>

typedef NS_OPTIONS(NSUInteger, DNRControlEvents) {
    DNRControlEventTouchDown                                         = 1 <<  0,      // on all touch downs
    DNRControlEventTouchDownRepeat                                   = 1 <<  1,      // on multiple touchdowns (tap count > 1)
    DNRControlEventTouchDragInside                                   = 1 <<  2,
    DNRControlEventTouchDragOutside                                  = 1 <<  3,
    DNRControlEventTouchDragEnter                                    = 1 <<  4,
    DNRControlEventTouchDragExit                                     = 1 <<  5,
    DNRControlEventTouchUpInside                                     = 1 <<  6,
    DNRControlEventTouchUpOutside                                    = 1 <<  7,
    DNRControlEventTouchCancel                                       = 1 <<  8,
    
    DNRControlEventValueChanged                                      = 1 << 12,     // sliders, etc.
    DNRControlEventPrimaryActionTriggered NS_ENUM_AVAILABLE_IOS(9_0) = 1 << 13,     // semantic action: for buttons, etc.
    
    DNRControlEventEditingDidBegin                                   = 1 << 16,     // UITextField
    DNRControlEventEditingChanged                                    = 1 << 17,
    DNRControlEventEditingDidEnd                                     = 1 << 18,
    DNRControlEventEditingDidEndOnExit                               = 1 << 19,     // 'return key' ending editing
    
    DNRControlEventAllTouchEvents                                    = 0x00000FFF,  // for touch events
    DNRControlEventAllEditingEvents                                  = 0x000F0000,  // for UITextField
    DNRControlEventApplicationReserved                               = 0x0F000000,  // range available for application use
    DNRControlEventSystemReserved                                    = 0xF0000000,  // range reserved for internal framework use
    DNRControlEventAllEvents                                         = 0xFFFFFFFF
};

#endif

#endif /* DNRControlEvents_h */
