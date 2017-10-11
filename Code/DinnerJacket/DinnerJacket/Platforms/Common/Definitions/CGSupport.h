//
//  CGSupport.h
//  DinnerJacket
//
//  Created by Nicolás Fernando Miari on 2016/09/14.
//  Copyright © 2016 Nicolás Miari. All rights reserved.
//

#ifndef CGSupport_h
#define CGSupport_h

#import "TargetConditionals.h"

#if TARGET_OS_IPHONE

#import <UIKit/UIKit.h>

#elif TARGET_OS_OSX

#import <Cocoa/Cocoa.h>

#define CGRectFromString NSRectFromString
#define CGPointFromString NSPointFromString
#define CGSizeFromString NSSizeFromString

#endif

#endif /* CGSupport_h */
