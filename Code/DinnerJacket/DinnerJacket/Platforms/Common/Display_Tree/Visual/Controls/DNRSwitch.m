//
//  DNRSwitch.m
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-08-03.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import "DNRSwitch.h"

@implementation DNRSwitch {

    BOOL    _on;
}


- (void) touchUpInside {

    _on = !_on;
    
    if (_on) {
        [self setState:DNRControlStateSelected];
    }
    else{
        [self setState:DNRControlStateNormal];
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


@end
