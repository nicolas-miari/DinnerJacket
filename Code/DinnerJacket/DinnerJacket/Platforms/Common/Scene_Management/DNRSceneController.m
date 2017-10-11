//
//  DNRSceneController.m
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-05-03.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import "DNRSceneController.h"

#import "DNRScene.h"
#import "DNRSceneTransition.h"

#ifdef DNRPlatformPhone
#import "../../iOS/ViewController/DNRViewController.h"
#else
#import "../../macOS/ViewController/DNRViewController.h"
#endif

#import "TimeController.h"

#import "DNRRenderer.h"


NSString* const SceneDidTickNotification = @"SceneDidTickNotification";

@interface DNRSceneController ()

/// The root of the display hierarchy. It is either a static scene node, or a
/// transition node between two scene nodes.
@property (nonatomic, readwrite) DNRNavigationNode* rootNode;


@end


@implementation DNRSceneController {
    
    DNRNavigationNode*  _rootNode;
    
    Color4f             _clearColor;
    
    id <DNRRenderer>    _renderer;
    
    
    DNRSceneTransitionType  _defaultTransitionType;
    CFTimeInterval          _defaultTransitionDuration;
    DNREasingType           _defaultTransitionEasingType;
}


+ (instancetype) defaultController {
    
    static id sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });
    
    return sharedInstance;
}


- (instancetype) init {
    
    if (self = [super init]) {
        _clearColor = Color4fWhite;
        
        _defaultTransitionType       = DNRSceneTransitionTypeSequentialFade;
        _defaultTransitionDuration   = 1.0f;
        _defaultTransitionEasingType = DNREaseInOut;

        // Register with the time controller
        // to be notified on every tick:
        [[TimeController sharedController] addSceneController:self];
    }
    
    return self;
}

- (void) dealloc {
    [[TimeController sharedController] removeSceneController:self];
}

#pragma mark - Custom Accessors


- (void) setRootNode:(DNRNavigationNode *)node {
    
    if (node != _rootNode) {

        [node becomeRootNode];

        id<DNRRenderer> renderer = [[DNRViewController sharedController] renderer];

        [node setRenderer:renderer];
        
        _rootNode = node;
    }
}


- (DNRNode *)displayRootNode {
    
    if ([_rootNode isKindOfClass:[DNRScene class]] ) {
        return _rootNode;
    }
    else{
        DNRSceneTransition* transition = (DNRSceneTransition*)_rootNode;
        return [transition currentScene];
    }
}


- (void) setClearColor:(Color4f)clearColor {
    
    _clearColor = clearColor;

    if (_renderer) {
        [_renderer setBackgroundClearColor:_clearColor];
    }
}


#pragma mark - Operation


- (void) runScene:(DNRScene *)nextScene {
    
    [self setRootNode:nextScene];
    
    [nextScene didEnter];
}


- (void) transitionToScene:(DNRScene *)nextScene
                  withType:(DNRSceneTransitionType) transitionType
                  duration:(CFTimeInterval) duration
                easingType:(DNREasingType) easingType {

    DNRScene* currentScene = nil;
    
    if ([_rootNode isKindOfClass:[DNRScene class]]) {
        /* 
         Displaying static scene: use it as starting scene of the transition.
         */
        
        currentScene = (DNRScene *)_rootNode;
    }
    else{
        /*
         Corner case: already transitioning between two scenes. Pick the scene 
         being (mostly) displayed right now as initial scene of the new 
         transition.
        */
        DNRSceneTransition* transition = (DNRSceneTransition *)_rootNode;
        
        if ([transition progress] <= 0.5) {
            currentScene = [transition scene1];
        }
        else{
            currentScene = [transition scene2];
        }
    }
    
    DNRSceneTransition* newTransition = [[DNRSceneTransition alloc] initWithType:transitionType
                                                                     sourceScene:currentScene
                                                                destinationScene:nextScene
                                                                        duration:duration
                                                                      easingType:easingType];
    [self setRootNode:newTransition];
    
    
    // Disable touch input during transition:
    // TODO: Find a workaround for macOS
    //[[[DNRViewController sharedController] view] setUserInteractionEnabled:NO];
}


- (void) transitionToScene:(DNRScene *)nextScene {
    
    [self transitionToScene:nextScene
                   withType:_defaultTransitionType
                   duration:_defaultTransitionDuration
                 easingType:_defaultTransitionEasingType];
}


#pragma mark -


- (void) tick:(CFTimeInterval) dt {
    
    [_rootNode tick:dt];
    /* 
     Calls itself recursively on whole tree, and calls -update: once on each
     node (parent before child)
    */
    
    if ([_rootNode isKindOfClass:[DNRScene class]]) {
        // Static scene: do nothing
    }
    else{
        // Scene Transition: check progress/completion
        
        DNRSceneTransition* transition = (DNRSceneTransition *)_rootNode;
        
        //[transition update:dt];
        
        if ([transition isComplete]) {
            
            [self setRootNode:[transition scene2]];
            
            // Restore touch input after transition:
            // TODO: Find a workaround for macOS
            //[[[DNRViewController sharedController] view] setUserInteractionEnabled:YES];
        }
    }
    
    // .. ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ..
    // Render
    
    [_rootNode draw];
    

#ifdef DNRPlatformMac

    [[NSNotificationCenter defaultCenter] postNotificationName:SceneDidTickNotification object:self];
    // TEST
    //NSView* view = [[DNRViewController sharedController] view];
    //[view setNeedsDisplay: YES];
#endif
}


@end
