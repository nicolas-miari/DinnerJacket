//
//  DNRNavigationNode.h
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-03-08.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import "DNRNode.h"


@protocol DNRRenderer;


/**
 
 */
@interface DNRNavigationNode : DNRNode


///
@property (nonatomic, readwrite, strong) id <DNRRenderer> renderer;


///
@property (nonatomic, readonly, getter = isTransition) BOOL transition;


/** 
 Scenes and transitions draw themselves; the scene controller only orchestrates 
 them.
 */
- (void) draw;


@end


