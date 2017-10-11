//
//  DNRViewController.m
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-05-03.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import "DNRViewController.h"           // Own header

#import "DNROpenGLESView.h"             // View object
#import "DNRTextureAtlas.h"
#import "DNRTexture.h"
#import "DNRGlobals.h"                  // Set scale factor

///
static DNRViewController *sharedInstance = nil;



@interface DNRViewController ()

///
@property (nonatomic, readwrite) DNROpenGLESView *glView;

///
@property (nonatomic, readwrite) CADisplayLink *displayLink;

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

    // First instance created gets to be the "singleton":
    if (sharedInstance == nil) {
        sharedInstance = self;
    }

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = self;
    });
    
    UIScreen* mainScreen = [UIScreen mainScreen];
    
    screenScaleFactor = (float)[mainScreen scale];
    // On 64 bit systems (iPhone 5s, Mac), the cast from 'CGFloat' to
    // 'float' is **not** redundant. (CGFloat uis actually defined as 'double')
    
    if ([mainScreen respondsToSelector:@selector(nativeScale)]) {
        // On some devices (e.g. iPhone 6 Plus) the nativeScale and scale are different
        // (logical resolution is downsampled to physical resolution);
        // we should avoid downsampling for performance and insted render at
        // the native resolution.
        
        screenScaleFactor = [mainScreen nativeScale];
        
        // TODO: Test on an actual iPhone 6 Plus!!!!
    }
}


#pragma mark - UIViewController Methods


- (void) loadView {
    
    // (Override so as to use an openGL view instead of a regular UIView)
    
    CGRect bounds = [[UIScreen mainScreen] bounds];
    
    _glView = [[DNROpenGLESView alloc] initWithFrame:bounds];
    
    [self setView:_glView];
}


- (void) didReceiveMemoryWarning {
    
    // TODO: Move to a class dedicated to resource management.
    // This has nothing to do with the view.
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    [DNRTextureAtlas purgeUnusedAtlases];
    [DNRTexture purgeUnusedTextures];
}


- (BOOL) prefersStatusBarHidden {
    return YES;
}


- (BOOL) shouldAutorotate {
    return YES;
}


- (UIInterfaceOrientationMask) supportedInterfaceOrientations {
    /* 
     The system intersects the view controller’s supported orientations with
     the app's supported orientations (as determined by the Info.plist file or
     the app delegate's application:supportedInterfaceOrientationsForWindow:
     method) to determine whether to rotate.
     
     So, return all orientations here and let the developer specify in Xcode
     target settings.
     */
    
    return UIInterfaceOrientationMaskAll;
}

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {

    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}



#pragma mark - DNRSceneControl Protocol Methods


- (id<DNRView>) glView {
    return _glView;
}


- (CGSize)screenSize{
    return [_glView frame].size;
}

- (id<DNRRenderer>) renderer{
    return  [_glView renderer];
}

- (id) backgroundRenderingContext {
    return  [_glView backgroundRenderingContext];
}

@end
