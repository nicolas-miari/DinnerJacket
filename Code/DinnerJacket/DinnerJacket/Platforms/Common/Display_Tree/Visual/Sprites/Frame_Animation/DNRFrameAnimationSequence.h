//
//  DNRFrameAnimationSequence.h
//  DinnerJacket
//
//  Created by Nicolás Miari on 2015/11/09/.
//  Copyright © 2015 Nicolas Miari. All rights reserved.
//

#import <Foundation/Foundation.h>

/** 
 */
@interface DNRFrameAnimationSequence : NSObject


///
@property (nonatomic, readonly) NSString* atlasName;


///
@property (nonatomic, readonly) NSArray* frames;


///
@property (nonatomic, readonly) NSArray* subimageNames;


///
@property (nonatomic, readonly) NSUInteger repeatCount;


/**
 */
+ (instancetype) animationSequenceNamed:(NSString *)name;


@end
