//
//  DNRSpriteFrame.m
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-11-03.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import "DNRSpriteFrame.h"


@implementation DNRSpriteFrame


- (instancetype) initWithSubimageName:(NSString *)subimageName
                             duration:(CFTimeInterval) duration {
    if (self = [super init]) {
        
        _subimageName = [subimageName copy];
        _duration     = duration;
    }
    
    return self;
}

@end
