//
//  DNRInputClaimPair.h
//  DinnerJacket
//
//  Created by Nicolás Fernando Miari on 2016/10/14.
//  Copyright © 2016 Nicolás Miari. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DNRNode;
@class DNRPointerInput;


@interface DNRInputClaimPair : NSObject

@property (nonatomic, readonly, weak) DNRNode *node;
@property (nonatomic, readonly      ) DNRPointerInput *input;

+ (instancetype) claimPairWithNode:(DNRNode *) node input:(DNRPointerInput *) input;

@end
