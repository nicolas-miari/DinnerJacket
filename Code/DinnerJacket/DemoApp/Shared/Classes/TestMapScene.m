//
//  TestMapScene.m
//  DinnerJacket
//
//  Created by n.miari on 8/5/14.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import "TestMapScene.h"

#import "DNRTextureAtlas.h"

#import "DNRMatrix.h"

#import "DNRTextureAtlas.h"



@interface TestMapScene ()

@property (nonatomic, strong) DNRSprite* indicator;
@property (nonatomic, strong) TileMap*   map;
@property (nonatomic)         BOOL       mapLoaded;
@property (nonatomic)         NSUInteger spritesWaiting;

@end


@implementation TestMapScene


- (instancetype) init {
    
    if (self = [super init]) {
        
        _indicator = [[DNRSprite alloc] initWithSize:CGSizeMake(100.0f, 100.0f)
                                               color:Color4fBlue];
        [self addChild:_indicator];
        
        
        [DNRTextureAtlas loadTextureAtlasNamed:@"Sprites01" completion:^(NSArray *loadedObjects) {
            // All map obejcts dependant on the atlas can now be loaded; begin
            // loading the map:
            [self loadTilemap];
        }];
    }
    
    return self;
}


- (void) loadTilemap {

    NSString* path = [[NSBundle mainBundle] pathForResource:@"Stage06" ofType:@"plist"];
    
    NSDictionary* mapDictionary = [NSDictionary dictionaryWithContentsOfFile:path];
    
    _map = [[TileMap alloc] initWithDictionary:mapDictionary
                                    dataSource:self];
}


#pragma mark Tile Map Data Source


- (DNRNode *)instanceOfMapObjectWithIdentifier:(NSString *)identifier {

    // Provide instances of map objects based on identifier (class name)
    
    // (Called on background thread - load textures synchronously)
    
    
    if ([identifier isEqualToString:@"Heart"]) {
    
        DNRSprite* heart = [[DNRSprite alloc] initWithAnimationSequenceNamed:@"HeartAnimation"];
        
        [heart startAnimating];
        
        return heart;
    }
    
    return nil;
}


#pragma mark - NSNotification Handlers


- (void) spriteBecameReady:(NSNotification *)notification {
    
    _spritesWaiting--;
    
    if (_spritesWaiting == 0) {
        
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        
        if (_mapLoaded && ![_map parent]) {
            [self addChild:_map];
        }
    }
}


#pragma mark - Internal Operation


- (void) mapDidLoad {
    
    _mapLoaded = YES;
    
    [self addChild:_map];
}


- (void) mapObjectsLoaded {
    
}


#pragma mark -


- (void) update:(CFTimeInterval) dt {
    
    static CFTimeInterval counter = 0.0f;
    
    counter += dt;
    
    CGFloat arg0 = 1.0f*counter;
    
    CGPoint position = CGPointMake(0.0f, 100.0f*sinf(arg0));
    [_indicator setPosition: position];
    
    static GLfloat localTransform[16];
    
    mat4f_LoadZRotation(arg0, localTransform);
    
    [_indicator setLocalTransform:localTransform];
    
    
    static BOOL beganLoadingMap = NO;
    
    if ((counter > 3.0f) && (!beganLoadingMap)) {
        
        beganLoadingMap = YES;
        
        [self addChild:_indicator];
        
        [_map beginAsyncLoadingWithCompletionHandler:^(void){
            
            // Map is ready to be rendered; add it to node hierarchy:
            
            [self mapDidLoad];
        }];
    }
    
    CGFloat xAmplitude = 0.5f*([_map layerSize].width * [_map tileSize] - 320);
    CGFloat yAmplitude = 0.5f*([_map layerSize].height * [_map tileSize] - 568);
    
    CGFloat arg1 = 1.25*counter/2;
    CGFloat arg2 = 2.17*counter/2;
    
    [_map setPosition:CGPointMake(xAmplitude*cosf(arg1),
                                  yAmplitude*cosf(arg2))];
}

@end
