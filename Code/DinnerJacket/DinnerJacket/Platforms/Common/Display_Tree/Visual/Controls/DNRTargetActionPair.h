//
//  DNRTargetActionPair.h
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-08-03.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//


#import "DNRControlEvents.h"


@interface DNRTargetActionPair : NSObject

@property (nonatomic, readonly) id target;
@property (nonatomic, readonly) DNRControlEvents events;
@property (nonatomic, readonly) SEL action;

- (instancetype) initWithTarget:(id) target
                         action:(SEL) action
                  controlEvents:(DNRControlEvents) events;


- (void) trigger:(id) sender;

@end
