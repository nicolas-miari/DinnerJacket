//
//  DNRButton.m
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-08-02.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import "DNRButton.h"



@implementation DNRButton {

    // (nothing yet)
}


// Factory

+ (instancetype) buttonWithNormalSprite:(DNRSprite *)normalSprite
                      highlightedSprite:(DNRSprite *)highlightedSprite {

    return [[self alloc] initWithNormalSprite:normalSprite
                            highlightedSprite:highlightedSprite];
}

/*
 Experiment - Succeeded.
- (BOOL) swallowsTouches {
    return NO;
}
*/

@end
