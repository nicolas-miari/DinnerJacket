//
//  DNRSwitch.h
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-08-03.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import "DNRControl.h"

@interface DNRSwitch : DNRControl


// Superclass method overrides

- (DNRControlState) stateAfterTouchEnded;

- (DNRControlState) stateDuringDragOutside;

@end
