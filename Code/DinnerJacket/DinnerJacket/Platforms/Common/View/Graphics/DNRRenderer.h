//
//  DNRRenderer.h
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-05-03.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import <Foundation/Foundation.h>           // NSObject
#import <CoreGraphics/CoreGraphics.h>       // CGFloat

#import "Types.h"

/**
 */
@protocol DNRRenderer <NSObject>


///
@property (nonatomic, readwrite) Color4f backgroundClearColor;


///
@property (nonatomic, readwrite) Color4f sceneClearColor;

///
@property (nonatomic, readwrite) CGFloat zoomScale;

/// In points?
@property (nonatomic, readwrite) CGPoint scrollOffset;


// Static Frame

/** 
 Called at the beginning of the frame, before drawing a static scene. Performs
 necessary framebuffer setup and clears the screen.
 */
- (void) beginFrame;


/** 
 Called at the end of the frame, after drawing a static scene. Presents the 
 rendered color buffer to the operation system for display.
 */
- (void) endFrame;


// Sequential Fade (out -> in)

/**
 Called at the beginning of a sequential fade transition (first scene fades out, 
 then second scene fades in) to perform necessary setup.
 */
- (void) initializeSequentialFade;

/**
 */
- (void) beginSequentialFadeFrame;

/**
 */
- (void) blendSequentialFadePassWithOpacity:(CGFloat) opacity;


// Cross-Dissolve (simultaneous cross-fade)

/**
 */
- (void) beginCrossDissolveFramePass1;

/**
 */
- (void) beginCrossDissolveFramePass2;

/**
 */
- (void) blendCrossDissolvePassesWithProgress:(CGFloat) progress;


@end


