//
//  DinnerJacketUniversal.h
//  DinnerJacket
//
//  Created by Nicolás Fernando Miari on 2016/10/11.
//  Copyright © 2016 Nicolás Miari. All rights reserved.
//

#ifndef DinnerJacketUniversal_h
#define DinnerJacketUniversal_h

#import "TargetConditionals.h"
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
#import <DinnerJacket/DinnerJacket.h>
#else
#import <DinnerJacketMac/DinnerJacketMac.h>
#endif


#endif /* DinnerJacketUniversal_h */
