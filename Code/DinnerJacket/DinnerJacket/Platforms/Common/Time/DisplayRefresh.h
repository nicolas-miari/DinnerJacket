//
//  DisplayRefresh.h
//  DinnerJacket
//
//  Created by Nicolás Fernando Miari on 2016/10/11.
//  Copyright © 2016 Nicolás Miari. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DNRSceneController;

/**
 Protocol adopted by the object that manages display refresh (timer).
 Actual class is platform-dependant.
 */
@protocol DisplayRefresh <NSObject>

/// On instantiation, scene controller registers itself.
@property (nonatomic, readwrite) DNRSceneController *sceneController;


/// Singleton.
+ (instancetype) sharedController;

///
- (void) pause;

///
- (void) resume;


@end
