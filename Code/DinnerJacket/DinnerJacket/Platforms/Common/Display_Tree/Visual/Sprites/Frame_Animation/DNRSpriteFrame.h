//
//  DNRSpriteFrame.h
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-11-03.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

@import Foundation;


/**
 */
@interface DNRSpriteFrame : NSObject


///
@property (nonatomic, readonly) NSString*       subimageName;

///
@property (nonatomic, readonly) CFTimeInterval  duration;


/**
 */
- (instancetype) initWithSubimageName:(NSString *)subimageIndex
                              duration:(CFTimeInterval) duration;

@end
