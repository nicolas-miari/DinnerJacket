//
//  DNRTouchClaimPair.m
//  DinnerJacket
//
//  Created by Nicolás Fernando Miari on 2016/10/15.
//  Copyright © 2016 Nicolás Miari. All rights reserved.
//

#import "DNRTouchClaimPair.h"

@implementation DNRTouchClaimPair

+ (instancetype) claimPairWithNode:(DNRNode *) node touch:(UITouch *) touch {
    return [[self alloc] initWithNode:node touch:touch];
}

- (instancetype) initWithNode:(DNRNode *) node touch:(UITouch *) touch {
    if (self = [super init]) {
        _node  = node;
        _touch = touch;
    }
    return self;
}

@end
