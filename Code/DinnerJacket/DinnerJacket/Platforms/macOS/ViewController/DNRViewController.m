//
//  DNRViewController.m
//  DinnerJacketMac
//
//  Created by Nicolás Miari on 2014-05-03.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import "DNRBase.h"

#import "DNRViewController.h"           // Own header
#import "DNROpenGLView.h"             // View object
#import "DNRTextureAtlas.h"
#import "DNRTexture.h"
#import "DNRGlobals.h"                  // Set scale factor
#import "DNRRenderer.h"

#import "../Time/TimeController.h"

#import "DNRSceneController.h"

///
static DNRViewController *sharedInstance = nil;


@interface DNRViewController ()

///
@property (nonatomic, readwrite) DNROpenGLView *glView;

@end


@implementation DNRViewController

+ (instancetype) sharedController {
    
    if (sharedInstance == nil){
        sharedInstance = [self init];
    }
    
    return sharedInstance;
}


- (instancetype) initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder: aDecoder]){
        [self commonSetup];
    }
    
    return  self;
}

- (instancetype) init {
    if ((self = [super init])) {
        [self commonSetup];
    }
    
    return self;
}


- (void) commonSetup {

    if (sharedInstance == nil) {
        sharedInstance = self;
    }

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = self;
    });
    
    NSScreen* mainScreen = [NSScreen mainScreen];
    
    screenScaleFactor = (float)[mainScreen backingScaleFactor];
    // On 64 bit systems (iPhone 5s, Mac), the cast from 'CGFloat' to
    // 'float' is **not** redundant. (CGFloat uis actually defined as 'double')

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sceneDidTick:)
                                                 name:SceneDidTickNotification
                                               object:nil];
}

#pragma mark - Notification Handlers

- (void) sceneDidTick:(NSNotification*) notification {
    [self.view setNeedsDisplay: YES];
}

#pragma mark - UIViewController Methods


- (void) viewDidLoad {
    
    [super viewDidLoad];
    /*
    if ([[self view] isKindOfClass:[DNROpenGLView class]]){
        _glView = (DNROpenGLView*)[self view];
        return;
    }
    
    _glView = [[DNROpenGLView alloc] initWithFrame:self.view.frame];
    
    self.view = _glView;
    
    [[TimeController sharedController] resume];
     */
}

- (void) loadView {
    
    [super loadView];
    
    if ([[self view] isKindOfClass:[DNROpenGLView class]]){
        _glView = (DNROpenGLView*)[self view];
        return;
    }
    else {
        _glView = [[DNROpenGLView alloc] initWithFrame:self.view.frame];
        self.view = _glView;
    }
    
    [[TimeController sharedController] resume];
}

- (BOOL) prefersStatusBarHidden {
    return YES;
}

- (BOOL) shouldAutorotate {
    return YES;
}


#pragma mark - DNRSceneControl Protocol Methods


- (id<DNRView>) glView {
    return _glView;
}


- (CGSize)screenSize{
    return [_glView frame].size;
}

- (id<DNRRenderer>) renderer{
    
    DNROpenGLView* view = _glView;
    
    id<DNRRenderer> renderer = [view renderer];
    
    return  renderer;
}

- (id) backgroundRenderingContext {
    return  [_glView backgroundRenderingContext];
}

@end

