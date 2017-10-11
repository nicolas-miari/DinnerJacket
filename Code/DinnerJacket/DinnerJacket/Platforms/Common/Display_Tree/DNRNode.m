//
//  DNRNode.m
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-03-08.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import "DNRNode.h"

#import "DNRSceneController.h"

#import "DNRMatrix.h"

#import "DNRRenderer.h"

#import "DNRGlobals.h"      // scaleFactor

#import "DNRAction.h"


// .............................................................................
// Exported globals

NSInteger nodeInstanceCount = 0;


// .............................................................................
// Private globals

static DNRNode*  rootNode = nil;


// .............................................................................

@interface DNRNode ()

//@property (nonatomic, readwrite, weak) DNRNode* parent;
// -> Not needed - to set the value internally, we use the synthesized ivar
// _parent directly!

@end


// .............................................................................


@implementation DNRNode {

    // Holds children (source)
    NSMutableArray*     _children;
    
    
    // Copies children for recursive frame update
    NSMutableArray*     _childrenCopy;
    
    
    // Set directly
    GLfloat             _localTransform[16];
    
    // Updated based on _localTransform of ancestors,
    // all the way up to root node.
    GLfloat             _worldTransform[16];
    
    NSMutableArray*     _actionsInProgress;
    NSMutableArray*     _actionsToRemove;
}


#pragma mark - Initialization


+ (instancetype) allocWithZone:(struct _NSZone *)zone {

    id instance = [super allocWithZone:zone];
    
    if (instance) {
        // Keep track of the number of live instances, for memory debugging
        // purposes:
        nodeInstanceCount++;
    }
    
    return instance;
}

// Desingated Initializer

- (id) init {

    if ((self = [super init])) {

        // Set sensible default values:

        _tag                    = DNRNodeTagNotSet;
        _localizedName          = @"Unnamed Node";
        _visibility             = YES;
        _needsBlending          = YES;    // Meaningless unless drawsSelf?
        _alpha                  = 1.0f;
        _userInteractionEnabled = NO;     // contentless nodes should be transparent to touches
        
        _children = [NSMutableArray new];
        _childrenCopy = [NSMutableArray new];
        
        mat4f_LoadIdentity(_localTransform);
        mat4f_LoadIdentity(_worldTransform);
        
        _actionsInProgress = [NSMutableArray new];
        _actionsToRemove   = [NSMutableArray new];
    }
    
    return self;
}


- (void) dealloc {

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // Keep track of the number of live instances, for memory debugging
    // purposes:
    nodeInstanceCount--;
    
    [self removeAllChildren];
}


#pragma mark - Custom Accessors


+ (DNRNode *)rootNode {
    return rootNode;
}


- (GLfloat *)localTransform {
    return _localTransform;
}


- (void) setLocalTransform:(GLfloat *)localTransform {

    // Z scale of sprites must always be 1 in order for depth culling to work
    // properly:
    localTransform[10] = 1.0f;
    
    // Copy new matrix:
    memcpy(_localTransform, localTransform, 16*sizeof(GLfloat));
    
    // Propagate changes to own and descendant world transforms:
    [self propagateLocalTransformChanges];
}


- (CGPoint) position {

    CGPoint position = CGPointMake(_localTransform[12], _localTransform[13]);
    position.x /= screenScaleFactor;
    position.y /= screenScaleFactor;
    
    return position;
}


- (void) setPosition:(CGPoint) position {

    _localTransform[12] = (position.x) * screenScaleFactor;
    _localTransform[13] = (position.y) * screenScaleFactor;
    
    // Propagate changes to own and descendant world transforms:
    [self propagateLocalTransformChanges];
}


- (CGPoint) globalPosition {

    [self updateWorldTransform];
    
    return CGPointMake(_worldTransform[12] / screenScaleFactor,
                       _worldTransform[13] / screenScaleFactor);
}


- (float *)worldTransform {

    return _worldTransform;
}


- (void) updateWorldTransform {

    if (_parent) {
        // Child node. Recalculate our world transform based on parent's world
        //  transform and own local transform:
        
        GLfloat* parentWorldTransform = [_parent worldTransform];
        
        //                           A          x        B        =       C
        mat4f_MultiplyMat4f(parentWorldTransform, _localTransform, _worldTransform);
    }
    else{
        // Root node. Parent's "world transform" is assumed to be the identity:
        
        mat4f_CopyMat4f(_localTransform, _worldTransform);
    }
}


- (void) propagateLocalTransformChanges {

    // Called everytime our _localTransform is modified.
    
    // 1. Recalculate our own world transform, based on (unchanged) parent's
    //     world transform and own (just changed) local transform.
    
    [self updateWorldTransform];
    
    
    // 2. Make children update their world transforms, based on their
    //     (unchanged) local transforms and our (just updated) world transform.
    
    [_children makeObjectsPerformSelector:@selector(propagateLocalTransformChanges)];
}


- (BOOL) isVisibile {

    if (self == rootNode) {
        // Root node - intrinsic visibility is absolute:
        return _visibility;
    }
    else{
        // Non-root node - recursively dependant:
        return (_visibility && [_parent isVisible]);
        
        // (Effectively visible if and only if all ancestors, up to root, are
        // visible as well)
    }
    
    // (synthesized setter is OK, no need to override)
}


- (NSArray *)children {

    return [[NSArray alloc] initWithArray:_children];
    
    // ALTERNATIVELY: Forget about defensive programming and return the original array
    // (skip the allocation, for performance)
}


#pragma mark - Hit Test


- (BOOL) pointInGlobalCoordinatesIsWithinBounds:(CGPoint) globalPoint
                                  withTolerance:(CGFloat) tolerance {

    // The base DNRNode object is unbounded, so it always returns YES.
    // HOWEVER, the default behaviour for container nodes (DNRNode) is to not
    // claim (accept) or swallow (block) touches.
    //
    // Bounded subclasses (e.g., DNRSprite) should override this method and
    // inform wether the specified point lies within their bounds or not.
    
    
    return YES;
}


- (DNRNode *)hitTestWithPointInGlobalCoordinates:(CGPoint) globalPoint {

    /* Return the descendant that is furthest down in the node tree, containing
       the point.
     */
    DNRNode* target = nil;
    
    if ([self pointInGlobalCoordinatesIsWithinBounds:globalPoint withTolerance:0.0]) {
        // Point is inside own bounds
        
        target = self;
        
        for (DNRNode* child in [[_children reverseObjectEnumerator] allObjects]) {
            
            DNRNode* childTarget = [child hitTestWithPointInGlobalCoordinates:globalPoint];
            
            if (childTarget) {
                target = childTarget;
                break;
            }
        }
    }
    
    return target;
}


#pragma mark - Other Operation


- (void) runAction:(DNRAction *)action {

    [action setTarget:self];
    // -> Tells the action on what node to perform the changes every frame
    
    [_actionsInProgress addObject:action];
    // -> Causes the action to be updated every frame
}


#pragma mark - Frame Updates


- (void) update:(CFTimeInterval) dt {

    // (Base class does nothing. Game logic tipically goes here)
}


- (void) tick:(CFTimeInterval) dt {

    /* 
     IMPLEMENTATION DETAILS:
     
     Called every frame on the root node, and recursively on al descendants 
     (i.e., unparented nodes don't receive this message). In addition, it calls 
     the -update: method.

     
     SUBCLASSING NOTES:
     
     Subclasses should in principle NOT override this method (forgetting to call
     super would break the whole update cycle). Instead, subclasses should 
     override the -update: method and place all frame update logic there.
     */
    
    
    // Advance running actions
    for (DNRAction* action in _actionsInProgress) {
    
        [action update:dt];
        
        if ([action isComplete]) {
            [_actionsToRemove addObject:action];
        }
    }
    
    // Purge finished actions:
    [_actionsInProgress removeObjectsInArray:_actionsToRemove];
    [_actionsToRemove removeAllObjects];
    
    
    
    // Perform frame updates:
    [self update:dt];
    
    // (Note that this order causes -update: to get called first on the parent
    //  first, and then on its children)
    
    
    
    // Recurse on descendants:
    
    // NOTE: Game logic is performed inside many nodes' frame update methods. This
    // could entail adding or removing nodes to the graph, potentially causing
    // loop inconsistencies so we must iterate on a copy of the children array:
    // that is, the array children as it was at the moment this method was
    // called on their parent (before any additions/deletions are performed).
    
    [_childrenCopy removeAllObjects];
    [_childrenCopy addObjectsFromArray:_children];
    
    for (DNRNode* child in _childrenCopy) {
        [child tick:dt];
    }
    
    [_childrenCopy removeAllObjects];
}


#pragma mark - Rendering


- (BOOL) drawsSelf {
    // Graphic subclasses (e.g., sprites) should override to return YES, so the
    // method -render is called every frame.
    return NO;
}


- (BOOL) drawsDescendants {
    // Subclasses that perform custom drawing of children (e.g., a clipping
    // node) can override and return YES. In that case, the -render method will
    // NOT be automatically called on the receiver's descendants every frame.
    
    return NO;
}


- (NSComparisonResult) compareZ:(DNRNode *)otherNode {

    // Used for sorting nodes from farthest to closest (drawing)
    
    if ( (self->_z) > (otherNode->_z) ) {
        return NSOrderedDescending;
    }
    else{
        return NSOrderedAscending;
    }
}


- (NSComparisonResult) reverseCompareZ:(DNRNode *)otherNode {

    // Used for sorting nodes from closest to furthest (hit test)
    
    if ( (self->_z) < (otherNode->_z) ) {
        return NSOrderedDescending;
    }
    else{
        return NSOrderedAscending;
    }
}


- (void) render {

    /* Called every frame if -drawsSelf returns YES. Subclasses (e.g., sprites)
       must override and perform custom drawing calls.
     */
}


#pragma mark - Node Graph Manipulation


- (void) insertChild:(DNRNode *)newChild
             atIndex:(NSUInteger) insertIndex {
    /* 
     Every other child insertion method calls this one. Subclasses that wish to 
     bypass the internal representation should only override this method.
    */
    
    if (!newChild) {
        // Child can't be nil; ignore:
        return;
    }
    
    if (newChild == self) {
        // Can't be its own child; ignore:
        return;
    }
    
    
    DNRNode* oldParent = [newChild parent];
    
    if (oldParent == self) {
        // Already a child. Unless it's the first child, dettaching and
        // reattaching will shift the insertion index, so compensate.
        
        [self removeChild:newChild];
        
        if (insertIndex != 0) {
            insertIndex--;
        }
    }
    else{
        //  Just dettach from previous parent
        [oldParent removeChild:newChild];
    }
    
    
    // Clamp insert index to array bounds:
    NSUInteger safeIndex = insertIndex;
    
    if (safeIndex > [_children count]) {
        safeIndex = [_children count];
    }
    
    // Insert into array:
    [_children insertObject:newChild atIndex:safeIndex];
    
    
    // Parent it:
    newChild->_parent = self;
}


- (void) insertChild:(DNRNode *)newChild
          belowChild:(DNRNode *)existingChild {

    NSUInteger existingIndex;
    
    if (!existingChild || ((existingIndex = [_children indexOfObject:existingChild]) == NSNotFound)) {
        // Default to absolute bottom:
        [self insertChild:newChild atIndex:0];
    }
    else{
        // Insert below existing child:
        [self insertChild:newChild atIndex:existingIndex];
    }
}


- (void) insertChild:(DNRNode *)newChild
          aboveChild:(DNRNode *)existingChild {

    NSUInteger existingIndex;
    
    if (!existingChild || (existingIndex = [_children indexOfObject:existingChild]) == NSNotFound) {
        // Default to absolute top:
        [self addChild:newChild];
    }
    else{
        // Insert above existing child:
        [self insertChild:newChild atIndex:(existingIndex + 1)];
    }
}


- (void) addChild:(DNRNode *)newChild {

    // 'Add' is actually 'Insert at the very end':
    [self insertChild:newChild atIndex:[_children count]];
}


- (void) removeChild:(DNRNode *)child {

    if (child && child->_parent == self) {
        [_children removeObject:child];
        child->_parent = nil;
    }
}


- (void) removeAllChildren {

    // Beter not to modify the very array being iterated; use a copy:
    NSArray* childrenCopy = [NSArray arrayWithArray:_children];
    
    for (DNRNode* child in childrenCopy) {
        child->_parent = nil;
        [_children removeObject:child];
    }
}


- (void) removeFromParent {

    [_parent removeChild:self];
    _parent = nil;
}


- (DNRNode *)firstChildWithTag:(NSUInteger) tag {

    for (DNRNode* child in _children) {
        if (child->_tag == tag) {
            return child;
        }
    }
    
    return nil;
}


- (NSArray *)childrenWithTag:(NSUInteger)tag {

    NSMutableArray* childrenWithTag = [NSMutableArray new];
    
    for (DNRNode* child in _children) {
        if ([child tag] == tag) {
            [childrenWithTag addObject:child];
        }
    }
    
    return childrenWithTag;
}


- (void) sortChildrenUsingSelector:(SEL) selector {

    [_children sortUsingSelector:selector];
}


- (void) sortChildrenUsingComparator:(NSComparator) comparator {

    [_children sortUsingComparator:comparator];
}


- (NSUInteger) subtreeSize {

    /*
     Recursively calculates the total ammount of children, grandchildren,
     etc. below this node (the 'size' of the hierarchy subtree from this
     node below). The receiver (self) **IS** included in the count.
     */
    NSUInteger acc = 1; // Include self...
    
    for (DNRNode* child in _children) {
        
        acc += [child subtreeSize]; // (child itself is included in subtree)
    }
    
    return acc;
}


- (void) becomeRootNode {

    rootNode = self;
}


- (BOOL) isRootNode {

    return (self == rootNode);
}


#pragma mark - User Input


/* 
    Touch Architecture Outline
 
    (1) Hit test is performed on the display hierarchy tree, traversed in depth
         occlusion order (closer first, farther later).
 
    (2) Only nodes that can accept and/or block a touch are tested; the rest are 
         skipped (ignored).
 
    (3) The default behaviour for visually occluding nodes (e.g., sprites) is to
         claim and block touches (regardless if they actually respond to them or
         not, like e.g. a button).
 
    (4) The default behaviour for non-visually occluding nodes (e.g., container
         layers) is to ignore touches (hit test is skipped).
 
    (5) If a node blocks a touch, the hit test loop ends there (nodes deeper in
         the z tree are not tested).
 */

- (BOOL) isUserInteractionEnabled {

    /*
     Determines whether the receiver participates in hit tests or not.
     A node with user interaction disabled will be skipped altogether from the
     hit test loop.
     
     Examples:
     
     (A) A control (e.g. DNRButton) should participate in hit test because it
        can both claim (react to) and block touches from reaching other nodes
        beneath it.
     
     (B) A sprite (DNRSprite) should also participate in hit test, because even
        though it does not 'respond' to touches, it can still swallow (block) 
        them to prevent them from reaching an occluded control beneath it (of 
        course, a custom sprite subclass could do something with the touch).
     
     (C) A container node (DNRNode) should neither claim nor swallow (block)
        touches, so it should return NO.
     
     */
    
    return _userInteractionEnabled; // (Defaults to NO)
}


- (BOOL) swallowsTouches {

    /*
     Return YES to "swallow" a touch, regardless if it is claimed (tracked) or 
     not.

     To swallow a touch means that: 
     IF the hit test for the touch in the "touch began" phase passes for this
     node (i.e., touch location falls within the bounds of the node's defined 
     hit area), THEN the hit test ends here and all further nodes in the test's
     loop will be skipped (further nodes are "occluded" from the touch).
     
     If, in addition, we claim the touch, we will also receive notifications for
     all further phases (moved, ended, cancelled).
     
     Examples:
        (A) An opaque sprite (DNRSprite) should block touches within its bounds 
     from reaching (say) a button that lies beneath it, eventhough the sprite 
     itself does not "react" to the touch (i.e., claim it) in any way.
     
        (B) A container node (DNRNode) should let touches "pass through" and 
     potentially reach any controls lying beneath it (lower z).
     */
    
    return NO;
}


- (BOOL) inputBegan:(DNRPointerInput *) input {

    /* 
     Return YES to claim the touch. That means this node will continue to get 
     notified on subsequent phases of this touch (i.e.: moved, ended, 
     cancelled).
     
     Claiming a touch is independent of swallowing it:

     [1] Claiming means this node will receive notifications for the remaining
     phases of the touch's lifetime.
     
     [2] Swallowing means that no further nodes will be hit tested for this
     touch during the hit test of the "touch began" phase.
     
     Examples:
     
     (A) An opaque sprite (DNRSprite) should not claim touches (it is not a
     control or other custom input layer), but should swallow touches within its
     bounds to prevent them reaching (say) a button occluded by it.
     
     (B) A container node should not claim or swallow touches, but "let them 
     through" to reach any interested node down the depth tree.
     
     (C) A control (e.g., DNRButton) should both claim a touch (to track its
     further phases) and swallow it (to prevent it from reaching other nodes 
     occluded beneath).
     
     (D) A more 'exotic' node could claim a touch without swallowing it: it 
     would react to user input but allow other nodes further deep down the
     display herarchy to do so as well.
     
     */
    
    return NO;
}


- (void) inputMoved:(DNRPointerInput *) input {

    // Default implementation does nothing. Immediate subclasses need not call
    // super.
}


- (void) inputEnded:(DNRPointerInput *) input {

    // Default implementation does nothing. Immediate subclasses need not call
    // super.
}


- (void) inputCancelled:(DNRPointerInput *) input {

    // Default implementation does nothing. Immediate subclasses need not call
    // super.
}


@end
