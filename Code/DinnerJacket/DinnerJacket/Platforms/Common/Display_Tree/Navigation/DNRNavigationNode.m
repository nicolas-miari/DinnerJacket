//
//  DNRNavigationNode.m
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-03-08.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import "DNRNavigationNode.h"

#import "DLog.h"


@implementation DNRNavigationNode


- (BOOL) isTransition {
    DLog(@"Override me! (without calling super)");
    return NO;
}


- (void) draw {
    DLog(@"Override me! (without calling super)");
}


@end
