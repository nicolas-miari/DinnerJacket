//
//  DNREasingFunctions.h
//  Toutoulina
//
//  Created by n.miari on 8/14/14.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#ifndef __DNREasingFunctions__
#define __DNREasingFunctions__

#include <stdio.h>


typedef enum tDNREasingType {

    DNREaseLinear = 0,
    
    DNREaseIn,              // Global default, set to quadratic, cubuc, etc.
    DNREaseOut,
    DNREaseInOut,
    
    DNRQuadraticEaseIn,
    DNRQuadraticEaseOut,
    DNRQuadraticEaseInOut,
    
    DNRCubicEaseIn,
    DNRCubicEaseOut,
    DNRCubicEaseInOut,

    // (...)
    
    // TODO: Add more
    
    DNREaseTypeMax

}DNREasingType;


typedef float (*DNREasingFunction)(float);


// Linear interpolation (no easing)
float LinearInterpolation(float p);

// Quadratic easing; p^2
float QuadraticEaseIn(float p);
float QuadraticEaseOut(float p);
float QuadraticEaseInOut(float p);

// Cubic easing; p^3
float CubicEaseIn(float p);
float CubicEaseOut(float p);
float CubicEaseInOut(float p);

// Quartic easing; p^4
float QuarticEaseIn(float p);
float QuarticEaseOut(float p);
float QuarticEaseInOut(float p);

// Quintic easing; p^5
float QuinticEaseIn(float p);
float QuinticEaseOut(float p);
float QuinticEaseInOut(float p);

// Sine wave easing; sin(p * PI/2)
float SineEaseIn(float p);
float SineEaseOut(float p);
float SineEaseInOut(float p);

// Circular easing; sqrt(1 - p^2)
float CircularEaseIn(float p);
float CircularEaseOut(float p);
float CircularEaseInOut(float p);

// Exponential easing, base 2
float ExponentialEaseIn(float p);
float ExponentialEaseOut(float p);
float ExponentialEaseInOut(float p);


#endif /* defined(__DNREasingFunctions__) */
