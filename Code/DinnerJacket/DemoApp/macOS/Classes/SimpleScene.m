//
//  SimpleScene.m
//  DinnerJacket
//
//  Created by Nicolás Fernando Miari on 2016/10/11.
//  Copyright © 2016 Nicolás Miari. All rights reserved.
//

#import "SimpleScene.h"

#import "DNRTextureAtlas.h"

#import "DNRMatrix.h"

#import "DNRTextureAtlas.h"


@implementation SimpleScene
{
    DNRSprite* _sprite1;
    DNRSprite* _sprite2;
    
}

- (instancetype) init{
    if (self = [super init]){
        
        //[self setClearColor:Color4fRed];
        
        _sprite1 = [[DNRSprite alloc] initWithSize:CGSizeMake(100, 100) color:Color4fBlue];
        [self addChild:_sprite1];
        
        _sprite2 = [[DNRSprite alloc] initWithSize:CGSizeMake(50, 70) color:Color4fGreen];
        [_sprite2 setPosition:CGPointMake(75, 15)];
        
        [self addChild:_sprite2];
    }
    
    return self;
}

- (void) update:(CFTimeInterval) dt {
    
    static CFTimeInterval counter = 0.0f;
    
    //NSLog(@"dt: %.2f", dt);
    
    counter += dt;

    if (counter > 100.0) {
        counter = 0.0;
    }
    
    CGFloat arg0 = 1.0f*counter;
    
    //CGPoint position = CGPointMake(0.0f, 100.0f*sinf(arg0));
    //[_sprite1 setPosition: position];
    
    static GLfloat localTransform[16];
    
    mat4f_LoadZRotation(arg0, localTransform);
    
    [_sprite1 setLocalTransform:localTransform];

}


@end
