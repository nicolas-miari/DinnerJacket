//
//  DNRGLESView.m
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-05-03.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import "DNRBase.h"

#if defined (DNRPlatformPhone)

#import "DNROpenGLESView.h"
#import "DNROpenGLES2Renderer.h"
#import "DNRTexture.h"
#import "DNRNode.h"
#import "DNRNodeStack.h"
#import "DNRSceneController.h"
#import "DNRPointerInput.h"
#import "DNRTouchClaimPair.h"


@interface DNROpenGLESView ()

@property (nonatomic, readwrite) id <DNROpenGLESRenderer> renderer;
@property (nonatomic, readwrite) dispatch_queue_t serialDispatchQueue;
@property (nonatomic, readwrite) NSMutableArray* responderList;
@property (nonatomic, readwrite) DNRNodeStack*   responderStack;
@property (nonatomic, readwrite) NSMutableArray* claimPairs;

@end

// .............................................................................


@implementation DNROpenGLESView


+ (Class) layerClass {
    return [CAEAGLLayer class];
}


- (id) initWithFrame:(CGRect) frame
         colorFormat:(NSString *)colorFormat
   stencilBufferBits:(NSUInteger) stencilBits {

    if ((self = [super initWithFrame:frame])) {
        
        // Configure Core Animation layer
        
        CAEAGLLayer* eaglLayer = (CAEAGLLayer *)[self layer];
        [eaglLayer setOpaque:YES];
        
        NSDictionary* drawableProperties = @{
            kEAGLDrawablePropertyRetainedBacking : @(NO),
            kEAGLDrawablePropertyColorFormat     : (colorFormat ? colorFormat : kEAGLColorFormatRGBA8)
        };
        
        [eaglLayer setDrawableProperties:drawableProperties];
        
        
        [self setContentScaleFactor:[[UIScreen mainScreen] scale]];

        

        // 1. Instantiate OpenGL ES renderer
        
        _renderer = [[DNROpenGLES2Renderer alloc] initWithView:self
                                             stencilBufferBits:stencilBits];
        
        if (_renderer == nil) {
            // Abort:
            return (self = nil);
        }
        
        // Used in concert with background EAGLContext:
        _serialDispatchQueue = dispatch_queue_create("com.nicolasmiari.DinnerJacket.SerialQueue", NULL);
        
        
        // 2. Other UIView setup
        [self setMultipleTouchEnabled:YES];
        [self layoutSubviews];
        
        
        // 3. Custom touch event processing:
        [self setUserInteractionEnabled:YES];
        _claimPairs     = [NSMutableArray new];
        _responderList  = [NSMutableArray new];
        _responderStack = [DNRNodeStack new];
    }
    
    return self;
}


- (id) initWithFrame:(CGRect)frame {

    return [self initWithFrame:frame
                   colorFormat:nil
             stencilBufferBits:8];
}


- (void) layoutSubviews {

    [_renderer resizeFromLayer:(CAEAGLLayer*)[self layer]];
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

// .........................................................................

#pragma mark -


/**
 Traverse the whole display tree. Add every node that has user interaction
 enabled. Sort the list by depth.
 */
- (void) updateResponderList {

    [_responderList removeAllObjects];
    
    DNRNode* rootNode = [[DNRSceneController defaultController] displayRootNode];
    [_responderStack pushNode:rootNode];
    
    DNRNode* currentNode = nil;
    

    // Traverse whole tree and select nodes with user interaction enabled
    
    while ((currentNode = [_responderStack popNode])) {
        
        if ([currentNode isUserInteractionEnabled]) {
            [_responderList addObject:currentNode];
        }
        
        for (DNRNode* child in [currentNode children]) {
            [_responderStack pushNode:child];
        }
    }
    
    [_responderList sortUsingSelector:@selector(reverseCompareZ:)];
}


- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self dispatchTouches:touches withEvent:event atPhase:DNRPointInputPhaseBegan];
}


- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [self dispatchTouches:touches withEvent:event atPhase:DNRPointInputPhaseMoved];
}


- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self dispatchTouches:touches withEvent:event atPhase:DNRPointInputPhaseEnded];
}


- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self dispatchTouches:touches withEvent:event atPhase:DNRPointInputPhaseCancelled];
}


- (CGPoint) openGLCoordinatesOfUIKitPoint:(CGPoint) point {

    CGRect bounds = [self bounds];
    
    CGFloat x = point.x - 0.5f*(bounds.size.width);
    CGFloat y = 0.5f*(bounds.size.height) - point.y;
    
    return CGPointMake(x, y);
}


- (SEL) selectorForTouchPhase:(DNRPointInputPhase) phase {

    switch (phase) {
        case DNRPointInputPhaseBegan:
            return NSSelectorFromString(@"inputBegan:");
            break;
            
        case DNRPointInputPhaseMoved:
            return NSSelectorFromString(@"inputMoved:");
            break;
            
        case DNRPointInputPhaseEnded:
            return NSSelectorFromString(@"inputEnded:");
            break;
            
        case DNRPointInputPhaseCancelled:
            return NSSelectorFromString(@"inputCancelled:");
            break;
            
        default:
            return nil;
    }
}


- (void) dispatchTouches:(NSSet *)touches
               withEvent:(UIEvent *)event
                 atPhase:(DNRPointInputPhase) phase {

    [self updateResponderList];
    
    if (phase == DNRPointInputPhaseBegan) {
        
        for (UITouch *touch in touches) {

            // Perform hit test
            
            
            CGPoint touchGlobalLocation = [self openGLCoordinatesOfUIKitPoint:[touch locationInView:self]];
            
            for (DNRNode* node in _responderList) {
                if ([node pointInGlobalCoordinatesIsWithinBounds:touchGlobalLocation withTolerance:0.0]) {
                    // Within bounds...
                    
                    DNRPointerInput *input = [[DNRPointerInput alloc] initWithPhase:DNRPointInputPhaseBegan
                                                                         atLocation:touchGlobalLocation
                                                                          timestamp:touch.timestamp];
                    
                    if ([node inputBegan:input]) {
                        // Claimed - call subsequent phase notifications on this node
                        
                        DNRTouchClaimPair *claimPair = [DNRTouchClaimPair claimPairWithNode:node touch:touch];
                        [_claimPairs addObject:claimPair];
                    }
                    
                    if ([node swallowsTouches]){
                        // Swallowed - hit test loop for this touch ends here
                        break;
                    }
                }
            }
        }
    }
    else{
        // . .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .
        // MOVED, ENDED, CANCELLED PHASES
        
        // Find all nodes that have claimed the touch, and call the appropritate
        // method on them
        
        
        // 1. First, determine the selector for this touch phase
        SEL selector = [self selectorForTouchPhase:phase];
        
        
        // 2. Process all touches in order
        
        NSMutableArray* claimPairsProcessed = [NSMutableArray new];
        
        for (UITouch* touch in touches) {
            
            // Find nodes that claimed this touch
            
            for (DNRTouchClaimPair* claimPair in _claimPairs) {
                
                if ([claimPair touch] == touch) {
                    
                    CGPoint touchGlobalLocation = [self openGLCoordinatesOfUIKitPoint:[touch locationInView:self]];
                    
                    DNRPointerInput *input = [[DNRPointerInput alloc] initWithPhase:phase
                                                                         atLocation:touchGlobalLocation
                                                                          timestamp:touch.timestamp];
                    
                    DNRNode* targetNode = [claimPair node];
                    
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
            }
        }
        
        
        // . .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .
        // Clean up - Remove all helpers for touches that 'ended' or 'cancelled'
        
        if (phase != DNRPointInputPhaseMoved) {
            // Cancelled or ended

            [_claimPairs removeObjectsInArray:claimPairsProcessed];
        }
    }
}



@end

#endif // #if defined (DNRPlatformPhone)
