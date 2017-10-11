//
//  DNRGLESView.h
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-05-03.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DNRView.h"



@interface DNROpenGLESView : UIView <DNRView>


+ (Class) layerClass;


- (id) initWithFrame:(CGRect) frame;


- (CGPoint) openGLCoordinatesOfUIKitPoint:(CGPoint) point;


@end
