//
//  DNROpenGLScrollView.h
//  DinnerJacket
//
//  Created by Nicolás Fernando Miari on 2016/09/15.
//  Copyright © 2016 Nicolás Miari. All rights reserved.
//

#import "DNROpenGLView.h"

/**
 Scroll-capable OpenGL view. For use in level editors and other non-game 
 applications.
 */
@interface DNROpenGLScrollView : DNROpenGLView

@property (nonatomic, retain) IBOutlet NSScroller *horizontalScroller;

@property (nonatomic, retain) IBOutlet NSScroller *verticalScroller;

///
@property (nonatomic, readwrite) CGPoint scrollPosition;


@end
