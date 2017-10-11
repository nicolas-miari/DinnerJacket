//
//  DNRTargetActionPair.m
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-08-03.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import "DNRTargetActionPair.h"

@implementation DNRTargetActionPair {

    id __weak        _target;
    SEL              _action;
    DNRControlEvents _events;
}

@synthesize target = _target;
@synthesize action = _action;
@synthesize events = _events;



- (instancetype) initWithTarget:(id) target
                         action:(SEL) action
                  controlEvents:(DNRControlEvents) events {

    if (self = [super init]) {
        
        _target = target;
        _action = action;
        _events = events;
    }
    
    return self;
}


- (void) trigger:(id) sender {

    if (_target && _action) {
    
        IMP imp = [_target methodForSelector:_action];
        
        void (*func)(id, SEL, id) = (void *)imp;
        
        func(_target, _action, sender);
    }
}


@end
