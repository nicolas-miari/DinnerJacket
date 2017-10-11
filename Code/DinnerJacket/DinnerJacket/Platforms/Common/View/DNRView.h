//
//  DNRView.h
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-05-05.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol DNRRenderer;


/** 
 Declares methods and properties shared by the main view object on all 
 platforms.
 */
@protocol DNRView <NSObject>


/// The view's size, in points.
@property (nonatomic, readonly) CGSize size;


/** 
 The renderer object (actual class is platform specific; only adoption of the
 protocol DNRRenderer is guaranteed).
 */
@property (nonatomic, readonly) id <DNRRenderer> renderer;


/**
 The actual class depends on the platform.
 */
@property (nonatomic, readonly) id renderingContext;


/**
 The actual class depends on the platform.
 */
@property (nonatomic, readonly) id backgroundRenderingContext;


/**
 */
@property (nonatomic, readonly) dispatch_queue_t serialDispatchQueue;


/**
 */
@property (nonatomic, readwrite, getter=isUserInteractionEnabled) BOOL userInteractionEnabled;


@end

