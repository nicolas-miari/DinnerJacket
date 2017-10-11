//
//  DNRGlobals.h
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-03-08.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#ifndef __DNRGlobals_h__
#define __DNRGlobals_h__


#include "DNRBase.h"

// 2D Vertex Format

extern GLsizei stride2D;
extern GLvoid* positionOffset2D;
extern GLvoid* textureOffset2D;


// 3D Vertex Format

extern GLsizei stride3D;
extern GLvoid* positionOffset3D;
extern GLvoid* normalOffset3D;
extern GLvoid* textureOffset3D;
extern GLvoid* colorOffset3D;


/** 
 Screen scale factor: maps points to pixels (e.g. 2.0 in 'retina' devices).
 Made application-wide global for fast access.
 */
extern float   screenScaleFactor;


#endif  // #defined (__DNRGlobals_h__)
