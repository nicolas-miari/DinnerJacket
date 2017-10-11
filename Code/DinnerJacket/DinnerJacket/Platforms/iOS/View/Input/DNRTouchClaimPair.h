//
//  DNRTouchClaimPair.h
//  DinnerJacket
//
//  Created by Nicolás Fernando Miari on 2016/10/15.
//  Copyright © 2016 Nicolás Miari. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DNRNode;


@interface DNRTouchClaimPair : NSObject

@property (nonatomic, readonly, weak) DNRNode *node;
@property (nonatomic, readonly      ) UITouch *touch;

+ (instancetype) claimPairWithNode:(DNRNode *) node touch:(UITouch *) input;

@end
