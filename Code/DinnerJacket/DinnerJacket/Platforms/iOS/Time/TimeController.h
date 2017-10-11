//
//  TimeController.h
//  DinnerJacket
//
//  Created by Nicolás Miari on 2016/09/11.
//  Copyright © 2016 Nicolás Miari. All rights reserved.
//

#import <Foundation/Foundation.h>


@class DNRSceneController;


/**
 Manages time.
 */
@interface TimeController : NSObject

/// On instantiation, scene controller registers itself.
//@property (nonatomic, readwrite) DNRSceneController *sceneController;


/// Singleton.
+ (instancetype) sharedController;

///
- (void) addSceneController:(DNRSceneController *) controller;

///
- (void) removeSceneController:(DNRSceneController *)controller;

@end
