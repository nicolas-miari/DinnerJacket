//
//  DNRMatrix.h
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-03-08.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#ifndef __DNRMatrix_h__
#define __DNRMatrix_h__



void mat4f_LoadIdentity(float* m);

void mat4f_LoadScale(float* s, float* m);

int mat4f_Invert(float* m, float* invMatrixOut);

void mat4f_LoadXRotation(float radians, float* m);

void mat4f_LoadYRotation(float radians, float* m);

void mat4f_LoadZRotation(float radians, float* m);

void mat4f_LoadTranslation(float* v, float* mout);

void mat4f_LoadPerspective(float fov_radians, float aspect, float zNear, float zFar, float* mout);

void mat4f_LoadPerspective2(float fov_y, float aspect, float zNear, float zFar, float* mout);

void mat4f_LoadOrtho(float left, float right, float bottom, float top, float near, float far, float* mout);

void mat4f_MultiplyMat4f(const float* m1, const float* m2, float* mout);

void mat4f_CopyMat4f(const float* min, float* mout);

void mat4f_PrintMatrix4x4( const float*a );

void mat4f_PrintMatrix3x3( const float*a );

void mat4f_SubMatrix3x3(const float* a, float* mout);

void mat4f_MultiplyVec4f(const float* min, const float* vin, float* vout);



#endif  // #defined (__DNRMatrix_h__)
