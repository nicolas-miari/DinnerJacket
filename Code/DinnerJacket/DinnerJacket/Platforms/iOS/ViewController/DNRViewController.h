//
//  DNRViewController.h
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-05-03.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DNRRenderer;


/**
 Manages the OpenGL View.
 */
@interface DNRViewController : UIViewController


/// (in points, of course)
@property (nonatomic, readonly) CGSize screenSize;


/// Background OpenGL ES context. Same sharegroup as main context, queried to
/// create resources in a background thread.
@property (nonatomic, readonly) id backgroundRenderingContext;

///
@property (nonatomic, readonly) id<DNRRenderer> renderer;


///
+ (instancetype) sharedController;


/// Instantiation from xib.
- (instancetype) initWithCoder:(NSCoder *)aDecoder;


/// Programmatic instantiation.
- (instancetype) init;


@end


// .............................................................................
