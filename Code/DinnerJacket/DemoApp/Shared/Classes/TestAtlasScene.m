//
//  TestAtlasScene.m
//  DinnerJacket
//
//  Created by Nicolás Miari on 2016/09/10.
//  Copyright © 2016 Nicolás Miari. All rights reserved.
//

#import "TestAtlasScene.h"

#import "TestMapScene.h"

#import "DNRTextureAtlas.h"

#import "DNRFrameAnimationSequence.h"

#import "DNRAction.h"

#import "DNRButton.h"

#import "DNRMatrix.h"


@implementation TestAtlasScene

- (instancetype) init {
    
    if (self = [super init]) {
        
        [self setClearColor:Color4fBlue];
        
        [DNRTextureAtlas loadTextureAtlasNamed:@"Sprites01" completion:^(NSArray *loadedObjects) {
            
            // Heart loops forever:
            
            DNRSprite* heart = [[DNRSprite alloc] initWithAnimationSequenceNamed:@"HeartAnimation"];
            [self addChild:heart];
            [heart startAnimating];
            
            // Sparkle loops five times, then disappears:
            
            DNRSprite* sparkle = [[DNRSprite alloc] initWithAnimationSequenceNamed:@"SparkleAnimation"];
            [self addChild:sparkle];
            [sparkle startAnimatingWithCompletion:^{
                [self removeChild:sparkle];
            }];
            
            [sparkle setPosition:CGPointMake(0, 100)];
            
            
            DNRSprite* normal1      = [[DNRSprite alloc] initWithSize:CGSizeMake(50, 50) color:Color4fRed];
            DNRSprite* highlighted1 = [[DNRSprite alloc] initWithSize:CGSizeMake(100, 100) color:Color4fGreen];
            
            DNRButton* backButton = [[DNRButton alloc] initWithNormalSprite:normal1
                                                          highlightedSprite:highlighted1];
            [self addChild:backButton];
            
            [backButton setPosition:CGPointMake(-50, 50)];
            
            float local[16] = {0.0f};
            
            mat4f_LoadZRotation(1, local);
            
            [backButton setLocalTransform:local];
            
            [backButton addTarget:self
                           action:@selector(buttonAction:)
                 forControlEvents:DNRControlEventTouchUpInside];
            
            
            DNRSprite* normal2      = [[DNRSprite alloc] initWithSize:CGSizeMake(75, 75) color:Color4fYellow];
            DNRSprite* highlighted2 = [[DNRSprite alloc] initWithSize:CGSizeMake(120, 120) color:Color4fWhite];
            
            DNRButton* frontButton = [[DNRButton alloc] initWithNormalSprite:normal2
                                                           highlightedSprite:highlighted2];
            [self addChild:frontButton];
            
            [frontButton setPosition:CGPointMake(-150, -50)];
        }];
    }
    
    return self;
}

- (void) buttonAction:(id) sender {
    TestMapScene* mapScene = [TestMapScene new];
    
    [[DNRSceneController defaultController] transitionToScene:mapScene
                                                     withType:DNRSceneTransitionTypeSequentialFade
                                                     duration:1.0
                                                   easingType:DNREaseLinear];
}

- (void) didEnter{
    
    [super didEnter];
    
    /*
    DNRAction *action = [DNRAction waitForSeconds:5.0 completion:^{
        TestMapScene* mapScene = [TestMapScene new];
        
        [[DNRSceneController defaultController] transitionToScene:mapScene
                                                         withType:DNRSceneTransitionTypeSequentialFade
                                                         duration:1.0
                                                       easingType:DNREaseLinear];
    }];
    
    [self runAction:action];
     */
}

@end
