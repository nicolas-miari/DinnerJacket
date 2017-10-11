//
//  DNRPointerInput.m
//  DinnerJacket
//
//  Created by Nicolás Fernando Miari on 2016/10/14.
//  Copyright © 2016 Nicolás Miari. All rights reserved.
//

#import "DNRPointerInput.h"

@implementation DNRPointerInput

- (instancetype) initWithPhase:(DNRPointInputPhase) phase
                    atLocation:(CGPoint) location
                    timestamp:(NSTimeInterval) timestamp{
    
    if (self = [super init]) {
        _phase     = phase;
        _location  = location;
        _timestamp = timestamp;
    }
    
    return self;
}

+ (instancetype) inputWithPhase:(DNRPointInputPhase) phase
                     atLocation:(CGPoint) location
                     timestamp:(NSTimeInterval) timestamp {
    return [[self alloc] initWithPhase:(DNRPointInputPhase) phase
                            atLocation:location
                            timestamp:timestamp];
    
}
@end
