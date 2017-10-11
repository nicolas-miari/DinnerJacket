//
//  DNRNode.h
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-03-08.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import "Platform.h"

#if defined(DNRPlatformPhone)

#import <UIKit/UIKit.h>     // UITouch

#elif defined(DNRPlatformMac)

#import <Cocoa/Cocoa.h>

#endif


#define DNRNodeTagNotSet   -1


@class DNRAction;
@class DNRPointerInput;

/// Global variable that keeps track of live instances of the class/subclasses
/// (for memory debugging purposes)
extern NSInteger nodeInstanceCount;

/**
 The basic building block of the display hierarchy (display tree).
 Everything that appears on screen is a node. Some nodes perform custom drawing
 by themselves (e.g., sprites), while others act as containers to group one or
 more nodes and transform them together as a whole.
 */
@interface DNRNode : NSObject


/// The parent node. Except for the only root node, every node has a parent.
@property (nonatomic, readonly, weak) DNRNode *parent;


/// The node's children. Children are transformed according to the parent.
@property (nonatomic, readonly) NSArray *children;


/// The node's position, in the parent node's coordinate system.
@property (nonatomic, readwrite) CGPoint position;


/// The node's position in the global coordinate system (screen points).
@property (nonatomic, readwrite) CGPoint globalPosition;


/// The node's transformation matrix (4x4), in the parent node's coordinate
/// system.
@property (nonatomic, readwrite) GLfloat* localTransform;


/// The node's transformation matrix (4x4), in the global coordinate system.
/// Effectively, it equals the parent's world transform multiplied by the node's
/// local transform.
@property (nonatomic, readonly ) GLfloat* worldTransform;


/// Whether the node performs custom drawing of its contents or just acts as a
/// logical container for its children.
@property (nonatomic, readonly) BOOL drawsSelf;


/// Whether the node is responsible for drawing the contents of its children
/// (typically, not).
@property (nonatomic, readonly) BOOL drawsDescendants;


/// Whether the node requires alpha blending to be enabled to draw its contents.
/// For performance, only nodes that draw semitrasnparent fragments should set
/// this value to YES;
@property (nonatomic, readwrite) BOOL needsBlending;


/// The opacity value. Meaningful only if `needsBlending` is set to `YES`.
@property (nonatomic, readwrite) GLfloat alpha;


/// The drawing depth. Assigned by renderer each frame, when traversing the
/// display tree.
@property (nonatomic, readwrite) GLfloat z;


/// Nodes with visibility set to NO are not drawn.
@property (nonatomic, readwrite, getter = isVisible) BOOL visibility;


/// User defined integer value used for basic identification of the node (akin
/// to that of UIView).
@property (nonatomic, readwrite) NSUInteger tag;


/// User defined string value used for basic identification of the node.
@property (nonatomic, copy) NSString* localizedName;

///
@property (nonatomic, readwrite, getter = isUserInteractionEnabled) BOOL userInteractionEnabled;



/** 
 At any moment, there is exactly one root node in the hierarchy, and the class 
 as a whole keeps track of it.
 */
+ (DNRNode *)rootNode;


// Node Graph Manipulation

/** 
 */
- (void) addChild:(DNRNode *)child;

/** 
 */
- (void) insertChild:(DNRNode *)child atIndex:(NSUInteger) insertIndex;

/** 
 */
- (void) insertChild:(DNRNode *)newChild aboveChild:(DNRNode *)existingChild;

/** 
 */
- (void) insertChild:(DNRNode *)newChild belowChild:(DNRNode *)existingChild;


/** 
 Removes the specified node from the receiver's children. If the node is not
 among the children of the receiver, the message is silently ignored.
 */
- (void) removeChild:(DNRNode *)child;


/** 
 Removes all the children of the receiver. If the receiver has no children, the 
 method is silently ignored.
 */
- (void) removeAllChildren;


/** 
 Dettaches the receiver from its parent. If the receiver has no parent at the
 time the message is sent, it is silently ignored.
 */
- (void) removeFromParent;


// Node Graph Search


/** 
 Returns the first node in the array of children of the receiver to have a
 matching tag. If no such child is found, nil is returned.
 */
- (DNRNode *)firstChildWithTag:(NSUInteger) tag;


/** 
 Returns an array with all the child nodes of the receiver that have a matching 
 tag. If no such children are found, an empty array is returned.
 */
- (NSArray *)childrenWithTag:(NSUInteger) tag;


// Hit Testing

/** 
 */
- (BOOL) pointInGlobalCoordinatesIsWithinBounds:(CGPoint) globalPoint
                                  withTolerance:(CGFloat) tolerance;

/** 
 */
- (DNRNode *)hitTestWithPointInGlobalCoordinates:(CGPoint) globalPoint;


// Other Operation

/** 
 Causes the specified node action to be run on the receiver.
 */
- (void) runAction:(DNRAction *)action;


// Render Loop

/** 
 Called every frame on all nodes in the display hierarchy (display tree). 
 Override this method to implement frame update logic. The base class 
 implementation does nothing; calling super super is needed only if there are 
 intermediate classes in the hierarchy that override this method.
 */
- (void) update:(CFTimeInterval) dt;


/**
 Called every frame by scene controller on the root node, and by each node on 
 its children recursively. It also calls -update: on self. 
 Do not call directly or override: That would break the frame upates logic. 
 Instead, override -update: and put all frame update/logic code there.
 */
- (void) tick:(CFTimeInterval) dt;


/** 
 Called every frame on all nodes in the display hierarchy (tree). Subclasses 
 that perform custom drawing commands should do from within this method.
 */
- (void) render;


/** 
 Sorts from furthest to closest (for rendering).
 */
- (NSComparisonResult) compareZ:(DNRNode *)other;


/** 
 Sorts from closest to furthest (for hit testing).
 */
- (NSComparisonResult) reverseCompareZ:(DNRNode *)otherNode;


/** 
 */
- (void) sortChildrenUsingSelector:(SEL) selector;

/** 
 */
- (void) sortChildrenUsingComparator:(NSComparator) comparator;


/** 
 */
- (NSUInteger) subtreeSize;


/** 
 */
- (void) becomeRootNode;


/** 
 */
- (void) updateWorldTransform;


//#ifdef DNRPlatformPhone

/**
 */
- (BOOL) swallowsTouches;

/**
 */
- (BOOL) inputBegan:(DNRPointerInput *) input;

/**
 */
- (void) inputMoved:(DNRPointerInput *) input;

/**
 */
- (void) inputEnded:(DNRPointerInput *) input;

/**
 */
- (void) inputCancelled:(DNRPointerInput *) input;


//#else

// TODO: Think some OSX counterpart

//#endif


@end


