//
//  TimeController.h
//  DinnerJacketMac
//
//  Created by Nicolás Miari on 2016/09/11.
//  Copyright © 2016 Nicolás Miari. All rights reserved.
//

#import <CoreVideo/CoreVideo.h>

@class DNRSceneController;


/**
 Manages time. Notifies the scene controller on every frame.
 */
@interface TimeController : NSObject


///
@property (nonatomic, readonly) CVDisplayLinkRef displayLink;


/// On instantiation, scene controller registers itself.
//@property (nonatomic, readwrite) DNRSceneController *sceneController;


/// Singleton.
+ (instancetype) sharedController;


- (void) pause;

- (void) resume;

///
- (void) addSceneController:(DNRSceneController *) controller;

///
- (void) removeSceneController:(DNRSceneController *)controller;

@end
