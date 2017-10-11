//
//  DNRGLESView.m
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-05-03.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import "DNRBase.h"

#import "DNROpenGLView.h"
#import "DNROpenGL3Renderer.h"
#import "DNRTexture.h"
#import "DNRNode.h"
#import "DNRNodeStack.h"
#import "DNRSceneController.h"
#import "../Time/TimeController.h"
#import "DNROpenGLUtilities.h"

#import "DNRPointerInput.h"
#import "DNRInputClaimPair.h"


typedef NS_ENUM(NSUInteger, TouchEventType) {

    TouchEventTypeBegan,
    TouchEventTypeMoved,
    TouchEventTypeEnded,
    TouchEventTypeCancelled,
    
    TouchEventTypeMax
};

static NSOpenGLContext* sharedContext = nil;


@interface DNROpenGLView ()

@property (nonatomic, readwrite) id <DNROpenGLRenderer> renderer;
@property (nonatomic, readwrite) dispatch_queue_t serialDispatchQueue;
@property (nonatomic, readwrite) NSMutableArray *responderList;
@property (nonatomic, readwrite) DNRNodeStack *responderStack;
@property (nonatomic, readwrite) NSMutableArray *claimedInputPairs;

@end

// .............................................................................


@implementation DNROpenGLView


#pragma mark - Initilization

/*
- (instancetype) initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]){
        // Nothing for now...
    }
    
    return self;
}*/


- (id) initWithFrame:(CGRect) frame
         colorFormat:(NSString *)colorFormat
   stencilBufferBits:(NSUInteger) stencilBits {

    if ((self = [super initWithFrame:frame])) {
        [self commonSetup];
    }
    
    return self;
}


- (id) initWithFrame:(CGRect)frame {

    return [self initWithFrame:frame
                   colorFormat:nil
             stencilBufferBits:8];
}

- (void) awakeFromNib {
    [super awakeFromNib];
    [self commonSetup];
}

- (void) commonSetup {
    
    _responderList     = [NSMutableArray new];
    _responderStack    = [DNRNodeStack new];
    _claimedInputPairs = [NSMutableArray new];
    
    
    NSOpenGLPixelFormatAttribute attributes[] = {
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFADepthSize, 24,
        NSOpenGLPFAOpenGLProfile,
        NSOpenGLProfileVersion3_2Core,
        0
    };
    
    NSOpenGLPixelFormat* pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attributes];
    
    if (!pixelFormat){
        NSLog(@"No OpenGL pixel format");
    }

    // (Shared context will be nil if this is the first OpenGL view instantiated)
    NSOpenGLContext* context = [[NSOpenGLContext alloc] initWithFormat:pixelFormat shareContext:sharedContext];

    if (sharedContext == nil) {
        // ...in which case, we set the newly created context as the globally
        // shared one, for future instances to reference:
        sharedContext = context;
    }
    // (from the second instance on, they will use the global shared context)
    
#ifdef DEBUG
    CGLEnable([context CGLContextObj], kCGLCECrashOnRemovedFunctions);
#endif
    
    checkOpenGLError();
    
    [self setPixelFormat:pixelFormat];
    checkOpenGLError();
    [self setOpenGLContext:context];
    checkOpenGLError();
    [self setWantsBestResolutionOpenGLSurface:YES];
    checkOpenGLError();
    [self setAcceptsTouchEvents:YES]; // NEEDED?
    
    checkOpenGLError();

    // TEST
    [context makeCurrentContext];

    _renderer = [[DNROpenGL3Renderer alloc] initWithView:self stencilBufferBits:0];
}


- (void) dealloc {
    // TODO: Adapt this logic to our TimeController design.
    
    /*
    // Stop the display link BEFORE releasing anything in the view
    // otherwise the display link thread may call into the view and crash
    // when it encounters something that has been release
    CVDisplayLinkStop(_displayLink);
    
    CVDisplayLinkRelease(_displayLink);
    
    // Release the display link AFTER display link has been released
    renderer = nil;
     */
}


#pragma mark - NSOpenGLView


- (void) prepareOpenGL {
    [super prepareOpenGL];
    
    [[self openGLContext] makeCurrentContext];
    
    GLint swapInterval = 1;
    [[self openGLContext] setValues:&swapInterval forParameter:NSOpenGLCPSwapInterval];
    
    _renderer = [[DNROpenGL3Renderer alloc] initWithView:self stencilBufferBits:0];
    
    CVDisplayLinkRef displayLink = [[TimeController sharedController] displayLink];
    
    // Set the display link for the current renderer
    CGLContextObj cglContext = [[self openGLContext] CGLContextObj];
    CGLPixelFormatObj cglPixelFormat = [[self pixelFormat] CGLPixelFormatObj];
    CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink, cglContext, cglPixelFormat);
}


- (void) reshape {
    /*
     Called by Cocoa when the view's visible rectangle or bounds change.
     Cocoa typically calls this method during scrolling and resize operations 
     but may call it in other situations when the view's rectangles change. The 
     default implementation does nothing. You can override this method if you 
     need to adjust the viewport and display frustum.
     */
    
    [super reshape];

    
    // We draw on a secondary thread through the display link. However, when
    // resizing the view, -drawRect is called on the main thread.
    // Add a mutex around to avoid the threads accessing the context
    // simultaneously when resizing.
    CGLLockContext([[self openGLContext] CGLContextObj]);

    NSRect viewRectPoints = [self visibleRect]; //[self bounds];
    NSRect viewRectPixels = [self convertRectToBacking:viewRectPoints];
    
    [_renderer resizeWithWidth:viewRectPixels.size.width
                        height:viewRectPixels.size.height];
    
    CGLUnlockContext([[self openGLContext] CGLContextObj]);
}

- (void)renewGState {
    /*
     Called whenever graphics state updated (such as window resize)
    
     OpenGL rendering is not synchronous with other rendering on the OSX.
     Therefore, call disableScreenUpdatesUntilFlush so the window server
     doesn't render non-OpenGL content in the window asynchronously from
     OpenGL content, which could cause flickering.  (non-OpenGL content
     includes the title bar and drawing done by the app with other APIs)
     */
    [[self window] disableScreenUpdatesUntilFlush];
    
    [super renewGState];
}


#pragma mark - NSView

- (BOOL) acceptsFirstResponder {
    return YES;
}

- (void) drawRect:(NSRect)dirtyRect {
    // Called during resize operations
    
    // Avoid flickering during resize by drawing
    //[self drawView];
    
    // Trigger a draw
    //[[DNRSceneController defaultController] tick:0.0];
    // (It could be a static frame, transition, etc. so leave it to the scene
    // controller)
    
    // If it doesn't work, just give it up and take the flicker during resize.
    // Who resizes a game window mid-play, anyway? And level editors should be
    // fine with the flicker...
    
    [[self openGLContext] makeCurrentContext];
    
    CGLLockContext([[self openGLContext] CGLContextObj]);
    
    [[DNRSceneController defaultController] tick:0.0];
    
    CGLFlushDrawable([[self openGLContext] CGLContextObj]);
    CGLUnlockContext([[self openGLContext] CGLContextObj]);
}


#pragma mark - Custom Accessors


- (id<DNRRenderer>) renderer {
    return _renderer;
}

- (id) renderingContext {
    return [_renderer context];
}

- (id) backgroundRenderingContext {
    return [_renderer backgroundContext];
}

- (dispatch_queue_t) serialDispatchQueue {
    return _serialDispatchQueue;
}

- (CGSize) size {
    return [self frame].size;
}


- (void) setUserInteractionEnabled:(BOOL)userInteractionEnabled {
    // TODO: Implement
}


- (BOOL) isUserInteractionEnabled {
    // TODO: Implement
    return YES;
}


// .........................................................................

#pragma mark -

/**
 Traverse the whole display tree. Add every node that has user interaction
 enabled. Sort the list by tree depth.
 */
- (void) updateResponderList {

    [_responderList removeAllObjects];
    
    DNRNode* rootNode = [[DNRSceneController defaultController] displayRootNode];
    [_responderStack pushNode:rootNode];
    
    DNRNode* currentNode = nil;
    
    while ((currentNode = [_responderStack popNode]) != nil) {
        
        if ([currentNode isUserInteractionEnabled]) {
            [_responderList addObject:currentNode];
        }
        
        for (DNRNode* child in [currentNode children]) {
            [_responderStack pushNode:child];
        }
    }
    
    [_responderList sortUsingSelector:@selector(reverseCompareZ:)];
}

- (void) mouseDown:(NSEvent *)event {
    
    CGPoint locationInView = [self convertPoint:[event locationInWindow] fromView:nil];
    CGPoint worldLocation = [self openGLCoordinatesOfAppKitPoint:locationInView];
    
    DNRPointerInput *input = [DNRPointerInput inputWithPhase:DNRPointInputPhaseBegan
                                                  atLocation:worldLocation
                                                  timestamp:event.timestamp];

    [self dispatchInput:input];
}

- (void) mouseUp:(NSEvent *)event {
    
    CGPoint locationInView = [self convertPoint:[event locationInWindow] fromView:nil];
    CGPoint worldLocation = [self openGLCoordinatesOfAppKitPoint:locationInView];
    
    DNRPointerInput *input = [DNRPointerInput inputWithPhase:DNRPointInputPhaseEnded
                                                  atLocation:worldLocation
                                                   timestamp:event.timestamp];
    
    [self dispatchInput:input];
}


- (void) mouseDragged:(NSEvent *)event {
    
    CGPoint locationInView = [self convertPoint:[event locationInWindow] fromView:nil];
    CGPoint worldLocation = [self openGLCoordinatesOfAppKitPoint:locationInView];
    
    DNRPointerInput *input = [DNRPointerInput inputWithPhase:DNRPointInputPhaseMoved
                                                  atLocation:worldLocation
                                                   timestamp:event.timestamp];
    [self dispatchInput:input];
}


- (CGPoint) openGLCoordinatesOfAppKitPoint:(CGPoint) point {
    
    CGSize size = self.bounds.size;
    CGFloat x = point.x - 0.5f*(size.width );
    CGFloat y = point.y - 0.5f*(size.height);
    return CGPointMake(x, y);
}


- (void) dispatchInput:(DNRPointerInput *)input {
    
    // TODO: Now that we do not depend on unmodifiable classes anymore (e.g.,
    // UITouch) move the type into input and have only one argument.

    [self updateResponderList];
    
    DNRPointInputPhase phase = [input phase];
    
    if (phase == DNRPointInputPhaseBegan) {
        
        // Perform Hit Test
        
        for (DNRNode* node in _responderList) {
            
            if ([node pointInGlobalCoordinatesIsWithinBounds:input.location withTolerance:0.0]) {
                // Within bounds...
                
                if ([node inputBegan:input] == YES) {
                    // Node has claimed the input. Store the claim pair in order
                    // to call subsequent phase methods on this node.
                    
                    DNRInputClaimPair *claimPair = [DNRInputClaimPair claimPairWithNode:node input:input];
                    [_claimedInputPairs addObject:claimPair];
                }
                
                if ([node swallowsTouches]){
                    // Swallowed - hit test loop for this touch ends here
                    break;
                }
            }
        }
    }
    else{
        // Mouse Dragged and Mouse Up
        
        // Find all nodes that have claimed the input, and call the appropritate
        // method on them.
        
        
        // 1. First, determine the selector for this input phase
        
        SEL selector;
        if (phase == DNRPointInputPhaseMoved) {
            selector = NSSelectorFromString(@"inputMoved:");
        }
        else if (phase == DNRPointInputPhaseEnded){
            selector = NSSelectorFromString(@"inputEnded:");
        }
        else{
            return;
        }
        

        // 2. Process all claim pairs
        
        
        NSMutableArray* claimPairsProcessed = [NSMutableArray new];
        
        // Find nodes that claimed this touch
        
        for (DNRInputClaimPair* claimPair in _claimedInputPairs) {
            
            DNRNode *targetNode = claimPair.node;
            
            // Node might get deallocated as a result of some method
            // called inside a touch handler. Fortunately, it is defined
            // as a weak reference so in  that case it will be nil:
            if (targetNode) {
                
                // Find the node's method implementation for this phase's selector:
                
                IMP imp = [targetNode methodForSelector:selector];
                void (*func)(id, SEL, DNRPointerInput*)= (void *)imp;
                func(targetNode, selector, input);
                
                // (-performSelector:* causes ARC warning)
            }
            else{
                // (Target node was deallocated before the touch being
                //  tracked ended its life cycle)
            }
            
            [claimPairsProcessed addObject:claimPair];
        }
        
        // Clean up - Remove all helpers for touches that 'ended' or 'cancelled'
        if (phase != DNRPointInputPhaseMoved) {
            [_claimedInputPairs removeObjectsInArray:claimPairsProcessed];
        }
    }
}

@end
