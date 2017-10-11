//
//  TimeController.m
//  DinnerJacket
//
//  Created by Nicolás Miari on 2016/09/11.
//  Copyright © 2016 Nicolás Miari. All rights reserved.
//

#import "TimeController.h"
#import "DNRSceneController.h"


@interface TimeController ()

/// iOS-specific. Use CVDisplayLink on the mac (https://developer.apple.com/library/mac/documentation/QuartzCore/Reference/CVDisplayLinkRef/index.html).
@property (nonatomic, readwrite) CADisplayLink *displayLink;

///
@property (nonatomic, readwrite) NSMutableArray* sceneControllers;

@end


@implementation TimeController

+ (instancetype) sharedController {
    
    static id sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });
    
    return sharedInstance;
}


#pragma mark - Initialization


- (instancetype) init {

    if (self = [super init]){
        self.sceneControllers = [NSMutableArray new];

        [self registerNotifications];
    }
    
    return self;
}

- (void) registerNotifications {
    
    NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidBecomeActive:)
                               name:UIApplicationDidBecomeActiveNotification
                             object:nil];
    
    [notificationCenter addObserver:self
                           selector:@selector(applicationWillResignActive:)
                               name:UIApplicationWillResignActiveNotification
                             object:nil];
}

#pragma mark - Exposed Operation

- (void) addSceneController:(DNRSceneController *) controller {
    if ([self.sceneControllers containsObject:controller]) {
        return;
    }
    [self.sceneControllers addObject:controller];
}

- (void) removeSceneController:(DNRSceneController *)controller {
    [self.sceneControllers removeObject:controller];
}

#pragma mark - Internal Operation


- (void) pause {
    if (_displayLink) {
        [_displayLink invalidate];
        _displayLink = nil;
    }
}


- (void) resume {
    if (!_displayLink) {
        
        _displayLink = [CADisplayLink displayLinkWithTarget:self
                                                   selector:@selector(displayLinkTicked:)];
        
        //[_displayLink setFrameInterval:1];            // Deprecated in iOS 10
        [_displayLink setPreferredFramesPerSecond:60];  // Introduced in iOS 10
        
        [_displayLink addToRunLoop:[NSRunLoop currentRunLoop]
                           forMode:NSDefaultRunLoopMode];
    }
}


- (void) displayLinkTicked:(CADisplayLink *)displayLink {
    
    CFTimeInterval dt = [displayLink duration];

    for (DNRSceneController *controller in _sceneControllers) {
        [controller tick:dt];
    }
}


#pragma mark - Notification Handlers


- (void) applicationWillResignActive:(NSNotification *)notification {
    [self pause];
}


- (void) applicationDidBecomeActive:(NSNotification *)notifcation {
    [self resume];
}


@end
