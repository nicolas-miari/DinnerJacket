//
//  TimeController.m
//  DinnerJacketMac
//
//  Created by Nicolás Miari on 2016/09/11.
//  Copyright © 2016 Nicolás Miari. All rights reserved.
//

#import "TimeController.h"
#import "DNRSceneController.h"


@interface TimeController ()

/// macOS-specific. Use CVDisplayLink on the mac (https://developer.apple.com/library/mac/documentation/QuartzCore/Reference/CVDisplayLinkRef/index.html).
@property (nonatomic, readwrite) CVDisplayLinkRef displayLink;

///
@property (nonatomic, readwrite) CFTimeInterval dt;

///
@property (nonatomic, readwrite) CFTimeInterval currentTime;

///
@property (nonatomic, readwrite) NSMutableArray* sceneControllers;

- (void) displayLinkTicked;


@end

// This is the renderer output callback function
static CVReturn MyDisplayLinkCallback(CVDisplayLinkRef displayLink,
                                      const CVTimeStamp* now,
                                      const CVTimeStamp* outputTime,
                                      CVOptionFlags flagsIn,
                                      CVOptionFlags* flagsOut,
                                      void* displayLinkContext)
{
    // Tick
    TimeController* controller = (__bridge TimeController*) displayLinkContext;
    
    [controller performSelectorOnMainThread:@selector(displayLinkTicked) withObject:nil waitUntilDone:NO];
    
    return kCVReturnSuccess;
}


@implementation TimeController


+ (instancetype) sharedController {
    
    static id sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });
    
    return sharedInstance;
}


- (void) setCurrentTime:(CFTimeInterval) currentTime {

    _dt = currentTime - _currentTime;
    
    _currentTime = currentTime;
}


#pragma mark - Initialization


- (instancetype) init {

    if (self = [super init]){
        [self registerNotifications];

        _sceneControllers = [NSMutableArray new];

        _currentTime = 0.0f;
        _dt          = 0.0f;
    }
    
    return self;
}

- (void) registerNotifications {


    NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidBecomeActive:)
                               name:NSApplicationDidBecomeActiveNotification
                             object:nil];
    
    [notificationCenter addObserver:self
                           selector:@selector(applicationWillResignActive:)
                               name:NSApplicationWillResignActiveNotification
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
        
        CVDisplayLinkStop(_displayLink);
        CVDisplayLinkRelease(_displayLink);
        _displayLink = nil;
    }
}


- (void) resume {
    if (!_displayLink) {
        
        // Create a display link capable of being used with all active displays
        CVDisplayLinkCreateWithActiveCGDisplays(&_displayLink);
        
        // Set the renderer output callback function
        CVDisplayLinkSetOutputCallback(_displayLink, &MyDisplayLinkCallback, (__bridge void *)(self));
        
        
        // Activate the display link
        CVDisplayLinkStart(_displayLink);
        
        // Register to be notified when the window closes so we can stop the displaylink
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(windowWillClose:)
                                                     name:NSWindowWillCloseNotification
                                                   object:[NSApp mainWindow]];
    }
}


- (void) displayLinkTicked {

    CFTimeInterval dt;
    CFAbsoluteTime newCurrentTime = CFAbsoluteTimeGetCurrent();

    if (_currentTime == 0.0) {
        dt = 1.0/60.0;
    } else {
        dt = newCurrentTime - _currentTime;
    }

    _currentTime = newCurrentTime;

    for (DNRSceneController* controller in _sceneControllers) {
        [controller tick:dt];
    }
}


#pragma mark - Notification Handlers

- (void) windowWillClose:(NSNotification*) notification {
    [self pause];
}

- (void) applicationWillResignActive:(NSNotification *)notification {
    [self pause];
}


- (void) applicationDidBecomeActive:(NSNotification *)notifcation {
    [self resume];
}


@end
