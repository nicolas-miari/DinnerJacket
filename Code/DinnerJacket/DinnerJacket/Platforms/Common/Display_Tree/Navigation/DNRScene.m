//
//  DNRScene.m
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-03-08.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import "DNRScene.h"

#import "DNRNodeStack.h"
#import "DNRView.h"
#import "DNRSceneTransition.h"
#import "DNRGLCache.h"
#import "DNRRenderer.h"

@interface DNRScene ()

@property (nonatomic, readwrite) DNRNodeStack* nodeStack;
@property (nonatomic, readwrite) NSMutableArray* opaqueNodes;
@property (nonatomic, readwrite) NSMutableArray* translucentNodes;

@end


// .............................................................................


@implementation DNRScene


#pragma mark - Initialization


- (id) init {

    if ((self = [super init])) {
        
        _nodeStack = [DNRNodeStack new];
        
        _opaqueNodes      = [[NSMutableArray alloc] init];
        _translucentNodes = [[NSMutableArray alloc] init];
        
        [self setAlpha:0.5];
        [self setUserInteractionEnabled:YES];
        
        _clearColor = Color4fWhite;
    }
    
    return self;
}


#pragma mark - Operation


- (void) willEnter {
    // Override me!
}


- (void) didEnter {
    // Override me! But call super too!
    _entered = YES;
}


- (void) willExit {
    // Override me!
}


- (void) didExit {
    // Override me!
}


#pragma mark - DNRNode Method Overrides


- (BOOL) isVisible {

    DNRNode* rootNode = [DNRNode rootNode];
    
    if (self == rootNode) {
        // We are the root scene; always visible:
        return YES;
    }
    
    
    if ([rootNode isKindOfClass:[DNRSceneTransition class]]) {
        // Root node is a transition
        
        DNRSceneTransition* transition = (DNRSceneTransition *)rootNode;
        
        return [transition sceneIsVisible:self];
    }
    
    return NO;
}


#pragma mark - DNRNavigationNode Method Overrides


- (void) draw {

    // Called by scene controller. Performs static scene drawing.
    
    
    id <DNRRenderer> renderer = [self renderer];
    
    bindFramebuffer(0);
    
    clearColor(_clearColor);
    
    [renderer beginFrame];
    
    [self drawNodes];
    
    [renderer endFrame];
}


- (void) drawNodes {

    // Draws the specified scene. It can be either the only scene, or one of
    //  two scenes in a transition.
    
    
    // 0. First, assign a Z (depth) value to each node in the hierarchy, by
    //     traversing the display tree in a depth-first fashion. Also, separate
    //     opaque nodes from translucent nodes to render in separate passes.
    
    
    
    NSUInteger treeSize = [self subtreeSize];   // (Recursive)
    
    CGFloat    step     = 1.0 / treeSize;       // z goes from 0.0 to 1.0 (viewing volume's depth)
    
    CGFloat    z        = 0.0f;                 // Begin drawing at the far back
    
    
    // .........................................................................
    // [ 1 ] First pass: Assign depths
    
    
    // Traverse depth first, increasing z from 0 to 1 by <step> for each node.
    
    DNRNode* currentNode = nil;
    
    [_nodeStack pushNode:self];
    
    while ((currentNode = [_nodeStack popNode])) {
        
        // 0. Assign z (depth)
        
        [currentNode setZ:z];
        
        // (...and increment z by <step> for
        //  the next node:)
        z += step;
        
        
        // Push children in reverse order
        
        NSEnumerator* reverseEnumerator = [[currentNode children] reverseObjectEnumerator];
        NSArray*      reverseChildren   = [reverseEnumerator allObjects];
        
        for (DNRNode* child in reverseChildren) {
            
            if ([child isVisible]) {
                
                [child updateWorldTransform];
                
                [_nodeStack pushNode:child];
            }
        }
    }
    
    // (Done assigning depths)
    
    
    // .........................................................................
    // [ 2 ] Second pass: split self-drawing nodes into opaque/non-opaque
    
    
    [_nodeStack pushNode:self];
    
    while ((currentNode = [_nodeStack popNode])) {
        
        // 1. Split self drawing nodes (e.g., GPSprite) into two groups,
        //     according to opacity:
        
        if ([currentNode drawsSelf]) {
            if ([currentNode needsBlending]) {
                
                [_translucentNodes addObject:currentNode];
            }
            else{
                [_opaqueNodes addObject:currentNode];
            }
        }
        
        // Push children in reverse order
        
        if (![currentNode drawsDescendants]) {
            
            NSEnumerator* reverseEnumerator = [[currentNode children] reverseObjectEnumerator];
            
            NSArray*      reverseChildren   = [reverseEnumerator allObjects];
            
            for (DNRNode* child in reverseChildren) {
                
                if ([child isVisible]) {
                    
                    [_nodeStack pushNode:child];
                }
            }
        }
    }
    
    // (done assigning Z and separating translucent from opaque nodes)
    
    
    // .........................................................................
    // Draw all (drawable) nodes at once
    
    
    // 1. Render Opaque Nodes First
    
    glDisable(GL_BLEND);
    [_opaqueNodes makeObjectsPerformSelector:@selector(render)];
    
    
    // 2. Render Translucent Nodes Second
    
    glEnable(GL_BLEND);
    [_translucentNodes makeObjectsPerformSelector:@selector(render)];
    
    
    // 3. Empty arrays in preparation for next frame:
    [_opaqueNodes removeAllObjects];
    [_translucentNodes removeAllObjects];
    
    // (done rendering scene)
}


@end
