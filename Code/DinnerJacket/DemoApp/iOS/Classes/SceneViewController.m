//
//  SceneViewController.m
//  DinnerJacket
//
//  Created by Nicolás Miari on 2016/09/11.
//  Copyright © 2016 Nicolás Miari. All rights reserved.
//

#import "SceneViewController.h"

#import "TestMapScene.h"
#import "TestAtlasScene.h"


@interface SceneViewController ()

@end

@implementation SceneViewController


- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    /*
     This is a custom subclass of the frameworks OpenGL-aware view controller, 
     that is set by default as the custom class of the initial view controller 
     on the main storyboard.
     
     Override -viewDidLoad and run your custom scene subclass as soon as the
     main view loads.
     */
    

    TestAtlasScene *scene = [TestAtlasScene new];
    
    [[DNRSceneController defaultController] runScene:scene];
}


@end
