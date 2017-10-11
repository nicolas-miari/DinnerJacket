//
//  ViewController.m
//  DemoMacApp
//
//  Created by Nicolás Fernando Miari on 2016/09/13.
//  Copyright © 2016 Nicolás Miari. All rights reserved.
//

#import "ViewController.h"
#import "TestMapScene.h"
#import "TestAtlasScene.h"
#import "SimpleScene.h"


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    
    
    TestAtlasScene* scene = [TestAtlasScene new];
    //SimpleScene* scene = [SimpleScene new];
    
    [[DNRSceneController defaultController] runScene:scene];
    
    
    /*
    DNRScene* scene = [DNRScene new];
    
    [scene setClearColor:Color4fRed];
    
    DNRSprite* sprite1 = [[DNRSprite alloc] initWithSize:CGSizeMake(100, 100) color:Color4fBlue];
    [scene addChild:sprite1];

    DNRSprite* sprite2 = [[DNRSprite alloc] initWithSize:CGSizeMake(50, 70) color:Color4fGreen];
    [sprite2 setPosition:CGPointMake(75, 15)];
    
    [scene addChild:sprite2];
    
    [[DNRSceneController defaultController] runScene:scene];
    */
    
    /*
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        DNRScene* scene2 = [[DNRScene alloc] init];
        scene2.clearColor = Color4fGreen;
        
        [[DNRSceneController defaultController] transitionToScene:scene2];
    });
     */
}


@end
