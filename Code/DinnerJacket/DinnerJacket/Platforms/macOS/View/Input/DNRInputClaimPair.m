//
//  DNRInputClaimPair.m
//  DinnerJacket
//
//  Created by Nicolás Fernando Miari on 2016/10/14.
//  Copyright © 2016 Nicolás Miari. All rights reserved.
//

#import "DNRInputClaimPair.h"

#import "DNRNode.h"
#import "DNRPointerInput.h"


@implementation DNRInputClaimPair

+ (instancetype) claimPairWithNode:(DNRNode *) node input:(DNRPointerInput *) input {
    return [[self alloc] initWithNode:node input:input];
}

- (instancetype) initWithNode:(DNRNode *) node input:(DNRPointerInput *) input {
    if (self = [super init]) {
        _node  = node;
        _input = input;
    }
    return self;
}

@end
