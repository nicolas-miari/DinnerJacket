//
//  DNRButton.h
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-08-02.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import "DNRControl.h"

@interface DNRButton : DNRControl

+ (instancetype) buttonWithNormalSprite:(DNRSprite *)normalSprite
                      highlightedSprite:(DNRSprite *)highlightedSprite;


@end
