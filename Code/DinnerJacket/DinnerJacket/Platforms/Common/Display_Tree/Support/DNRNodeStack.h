//
//  DNRNodeStack.h
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-03-08.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import <Foundation/Foundation.h>



@class DNRNode;


/**
 Stack of nodes for traversing the display hierarchy tree when rendering each 
 frame.
 */
@interface DNRNodeStack : NSObject


/// Pretty much what it says on the tin.
- (void) pushNode:(DNRNode *)node;


/// Pretty much what it says on the tin.
- (DNRNode *)popNode;


/// Pretty much what it says on the tin. Empties the stack.
- (void) empty;

@end

