//
//  DNRMatrix.c
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-03-08.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>         // malloc
#include <string.h>         // memcpy?
#include <math.h>

#include "DNRMatrix.h"      // Own header



static inline float fastAbs(float x) {

	return (x < 0) ? -x : x;
}


static inline float fastSinf(float x) {

	// fast sin function; maximum error is 0.001
	const float P = 0.225;
	
	x = x * M_1_PI;
	int k = (int) round(x);
	x = x - k;
    
	float y = (4 - 4 * fastAbs(x)) * x;
    
	y = P * (y * fastAbs(y) - y) + y;
    
	return (k&1) ? -y : y;
}


void mat4f_LoadIdentity(float* m) {

	m[0] = 1.0f;
	m[1] = 0.0f;
	m[2] = 0.0f;
	m[3] = 0.0f;
	
	m[4] = 0.0f;
	m[5] = 1.0f;
	m[6] = 0.0f;
	m[7] = 0.0f;
	
	m[8] = 0.0f;
	m[9] = 0.0f;
	m[10] = 1.0f;
	m[11] = 0.0f;
    
	m[12] = 0.0f;
	m[13] = 0.0f;
	m[14] = 0.0f;
	m[15] = 1.0f;
}

/* s is a C array of three floats. m is a C array of 16 floats.
 */
void mat4f_LoadScale(float* s, float* m) {

	m[0] = s[0];
	m[1] = 0.0f;
	m[2] = 0.0f;
	m[3] = 0.0f;
	
	m[4] = 0.0f;
	m[5] = s[1];
	m[6] = 0.0f;
	m[7] = 0.0f;
	
	m[8] = 0.0f;
	m[9] = 0.0f;
	m[10] = s[2];
	m[11] = 0.0f;
	
	m[12] = 0.0f;
	m[13] = 0.0f;
	m[14] = 0.0f;
	m[15] = 1.0f;
}


int mat4f_Invert(float* m, float* invOut) {

    double inv[16], det;
    int i;
    
    inv[0] = m[5]  * m[10] * m[15] -
    m[5]  * m[11] * m[14] -
    m[9]  * m[6]  * m[15] +
    m[9]  * m[7]  * m[14] +
    m[13] * m[6]  * m[11] -
    m[13] * m[7]  * m[10];
    
    inv[4] = -m[4]  * m[10] * m[15] +
    m[4]  * m[11] * m[14] +
    m[8]  * m[6]  * m[15] -
    m[8]  * m[7]  * m[14] -
    m[12] * m[6]  * m[11] +
    m[12] * m[7]  * m[10];
    
    inv[8] = m[4]  * m[9] * m[15] -
    m[4]  * m[11] * m[13] -
    m[8]  * m[5] * m[15] +
    m[8]  * m[7] * m[13] +
    m[12] * m[5] * m[11] -
    m[12] * m[7] * m[9];
    
    inv[12] = -m[4]  * m[9] * m[14] +
    m[4]  * m[10] * m[13] +
    m[8]  * m[5] * m[14] -
    m[8]  * m[6] * m[13] -
    m[12] * m[5] * m[10] +
    m[12] * m[6] * m[9];
    
    inv[1] = -m[1]  * m[10] * m[15] +
    m[1]  * m[11] * m[14] +
    m[9]  * m[2] * m[15] -
    m[9]  * m[3] * m[14] -
    m[13] * m[2] * m[11] +
    m[13] * m[3] * m[10];
    
    inv[5] = m[0]  * m[10] * m[15] -
    m[0]  * m[11] * m[14] -
    m[8]  * m[2] * m[15] +
    m[8]  * m[3] * m[14] +
    m[12] * m[2] * m[11] -
    m[12] * m[3] * m[10];
    
    inv[9] = -m[0]  * m[9] * m[15] +
    m[0]  * m[11] * m[13] +
    m[8]  * m[1] * m[15] -
    m[8]  * m[3] * m[13] -
    m[12] * m[1] * m[11] +
    m[12] * m[3] * m[9];
    
    inv[13] = m[0]  * m[9] * m[14] -
    m[0]  * m[10] * m[13] -
    m[8]  * m[1] * m[14] +
    m[8]  * m[2] * m[13] +
    m[12] * m[1] * m[10] -
    m[12] * m[2] * m[9];
    
    inv[2] = m[1]  * m[6] * m[15] -
    m[1]  * m[7] * m[14] -
    m[5]  * m[2] * m[15] +
    m[5]  * m[3] * m[14] +
    m[13] * m[2] * m[7] -
    m[13] * m[3] * m[6];
    
    inv[6] = -m[0]  * m[6] * m[15] +
    m[0]  * m[7] * m[14] +
    m[4]  * m[2] * m[15] -
    m[4]  * m[3] * m[14] -
    m[12] * m[2] * m[7] +
    m[12] * m[3] * m[6];
    
    inv[10] = m[0]  * m[5] * m[15] -
    m[0]  * m[7] * m[13] -
    m[4]  * m[1] * m[15] +
    m[4]  * m[3] * m[13] +
    m[12] * m[1] * m[7] -
    m[12] * m[3] * m[5];
    
    inv[14] = -m[0]  * m[5] * m[14] +
    m[0]  * m[6] * m[13] +
    m[4]  * m[1] * m[14] -
    m[4]  * m[2] * m[13] -
    m[12] * m[1] * m[6] +
    m[12] * m[2] * m[5];
    
    inv[3] = -m[1] * m[6] * m[11] +
    m[1] * m[7] * m[10] +
    m[5] * m[2] * m[11] -
    m[5] * m[3] * m[10] -
    m[9] * m[2] * m[7] +
    m[9] * m[3] * m[6];
    
    inv[7] = m[0] * m[6] * m[11] -
    m[0] * m[7] * m[10] -
    m[4] * m[2] * m[11] +
    m[4] * m[3] * m[10] +
    m[8] * m[2] * m[7] -
    m[8] * m[3] * m[6];
    
    inv[11] = -m[0] * m[5] * m[11] +
    m[0] * m[7] * m[9] +
    m[4] * m[1] * m[11] -
    m[4] * m[3] * m[9] -
    m[8] * m[1] * m[7] +
    m[8] * m[3] * m[5];
    
    inv[15] = m[0] * m[5] * m[10] -
    m[0] * m[6] * m[9] -
    m[4] * m[1] * m[10] +
    m[4] * m[2] * m[9] +
    m[8] * m[1] * m[6] -
    m[8] * m[2] * m[5];
    
    det = m[0] * inv[0] + m[1] * inv[4] + m[2] * inv[8] + m[3] * inv[12];
    
    if (det == 0){
        return 0;
    }
    
    det = 1.0 / det;
    
    for (i = 0; i < 16; i++) {
        invOut[i] = inv[i] * det;
    }
    
    return 1;
}


void mat4f_LoadXRotation(float radians, float* m) {

	float cosrad = fastSinf(M_PI_2 - radians);
	float sinrad = fastSinf(radians);
	
	m[0] = 1.0f;
	m[1] = 0.0f;
	m[2] = 0.0f;
	m[3] = 0.0f;
	
	m[4] = 0.0f;
	m[5] = cosrad;
	m[6] = sinrad;
	m[7] = 0.0f;
	
	m[8] = 0.0f;
	m[9] = -sinrad;
	m[10] = cosrad;
	m[11] = 0.0f;
	
	m[12] = 0.0f;
	m[13] = 0.0f;
	m[14] = 0.0f;
	m[15] = 1.0f;
}


void mat4f_LoadYRotation(float radians, float* mout) {

	float cosrad = fastSinf(M_PI_2 - radians);
	float sinrad = fastSinf(radians);
	
	mout[0] = cosrad;
	mout[1] = 0.0f;
	mout[2] = -sinrad;
	mout[3] = 0.0f;
	
	mout[4] = 0.0f;
	mout[5] = 1.0f;
	mout[6] = 0.0f;
	mout[7] = 0.0f;
	
	mout[8] = sinrad;
	mout[9] = 0.0f;
	mout[10] = cosrad;
	mout[11] = 0.0f;
	
	mout[12] = 0.0f;
	mout[13] = 0.0f;
	mout[14] = 0.0f;
	mout[15] = 1.0f;
}


void mat4f_LoadZRotation(float radians, float* mout) {

	float cosrad = fastSinf(M_PI_2 - radians);
	float sinrad = fastSinf(radians);
	
	mout[0] = cosrad;
	mout[1] = sinrad;
	mout[2] = 0.0f;
	mout[3] = 0.0f;
	
	mout[4] = -sinrad;
	mout[5] = cosrad;
	mout[6] = 0.0f;
	mout[7] = 0.0f;
	
	mout[8] = 0.0f;
	mout[9] = 0.0f;
	mout[10] = 1.0f;
	mout[11] = 0.0f;
	
	mout[12] = 0.0f;
	mout[13] = 0.0f;
	mout[14] = 0.0f;
	mout[15] = 1.0f;
}


// v is a 3D vector
void mat4f_LoadTranslation(float* v, float* mout) {

	mout[0] = 1.0f;
	mout[1] = 0.0f;
	mout[2] = 0.0f;
	mout[3] = 0.0f;
	
	mout[4] = 0.0f;
	mout[5] = 1.0f;
	mout[6] = 0.0f;
	mout[7] = 0.0f;
	
	mout[8] = 0.0f;
	mout[9] = 0.0f;
	mout[10] = 1.0f;
	mout[11] = 0.0f;
	
	mout[12] = v[0];
	mout[13] = v[1];
	mout[14] = v[2];
	mout[15] = 1.0f;
}


void mat4f_LoadPerspective(float fov_radians, float aspect, float zNear, float zFar, float* mout) {

	float f = 1.0f / tanf(fov_radians/2.0f);
	
	mout[0] = f / aspect;
	mout[1] = 0.0f;
	mout[2] = 0.0f;
	mout[3] = 0.0f;
	
	mout[4] = 0.0f;
	mout[5] = f;
	mout[6] = 0.0f;
	mout[7] = 0.0f;
	
	mout[8] = 0.0f;
	mout[9] = 0.0f;
	mout[10] = (zFar+zNear) / (zNear-zFar);
	mout[11] = -1.0f;
	
	mout[12] = 0.0f;
	mout[13] = 0.0f;
	mout[14] = 2 * zFar * zNear /  (zNear-zFar);
	mout[15] = 0.0f;
}


void mat4f_LoadPerspective2(float fov_y, float aspect, float zNear, float zFar, float* mout) {

    float yMax = zNear * tanf(fov_y * (float)M_PI / 360.0);
    float yMin = -yMax;
    float xMin = yMin * aspect;
    float xMax = yMax * aspect;
    
    float a = 2 * zNear / (xMax - xMin);
	float b = 2 * zNear / (yMax - yMin);
	float c = (xMax + xMin) / (xMax - xMin);
	float d = (yMax + yMin) / (yMax - yMin);
	float e = - (zFar + zNear) / (zFar - zNear);
	float f = -2 * zFar * zNear / (zFar - zNear);
    
    
    mout[ 0] = a;
	mout[ 1] = 0.0f;
	mout[ 2] = 0.0f;
	mout[ 3] = 0.0f;
	
	mout[ 4] = 0.0f;
	mout[ 5] = b;
	mout[ 6] = 0.0f;
	mout[ 7] = 0.0f;
	
	mout[ 8] = c;
	mout[ 9] = d;
	mout[10] = e;
	mout[11] = -1.0f;
	
	mout[12] = 0.0f;
	mout[13] = 0.0f;
	mout[14] = f;
	mout[15] = 1.0f;
}


void mat4f_LoadOrtho(float left, float right, float bottom, float top, float near, float far, float* mout) {

	float r_l = right - left;
	float t_b = top - bottom;
	float f_n = far - near;
	float tx = - (right + left) / (right - left);
	float ty = - (top + bottom) / (top - bottom);
	float tz = - (far + near) / (far - near);
    
	mout[0] = 2.0f / r_l;
	mout[1] = 0.0f;
	mout[2] = 0.0f;
	mout[3] = 0.0f;
	
	mout[4] = 0.0f;
	mout[5] = 2.0f / t_b;
	mout[6] = 0.0f;
	mout[7] = 0.0f;
	
	mout[8] = 0.0f;
	mout[9] = 0.0f;
	mout[10] = -2.0f / f_n;
	mout[11] = 0.0f;
	
	mout[12] = tx;
	mout[13] = ty;
	mout[14] = tz;
	mout[15] = 1.0f;
}


void mat4f_MultiplyMat4f(const float* m1, const float* m2, float* mout) {

    // 4x4行列のかけ算
    
	mout[ 0] = m1[ 0] * m2[ 0] + m1[4] * m2[ 1] + m1[ 8] * m2[ 2] + m1[12] * m2[ 3];
    mout[ 1] = m1[ 1] * m2[ 0] + m1[5] * m2[ 1] + m1[ 9] * m2[ 2] + m1[13] * m2[ 3];
    mout[ 2] = m1[ 2] * m2[ 0] + m1[6] * m2[ 1] + m1[10] * m2[ 2] + m1[14] * m2[ 3];
    mout[ 3] = m1[ 3] * m2[ 0] + m1[7] * m2[ 1] + m1[11] * m2[ 2] + m1[15] * m2[ 3];
    
    mout[ 4] = m1[ 0] * m2[ 4] + m1[ 4] * m2[ 5] + m1[ 8] * m2[ 6] + m1[12] * m2[ 7];
    mout[ 5] = m1[ 1] * m2[ 4] + m1[ 5] * m2[ 5] + m1[ 9] * m2[ 6] + m1[13] * m2[ 7];
    mout[ 6] = m1[ 2] * m2[ 4] + m1[ 6] * m2[ 5] + m1[10] * m2[ 6] + m1[14] * m2[ 7];
    mout[ 7] = m1[ 3] * m2[ 4] + m1[ 7] * m2[ 5] + m1[11] * m2[ 6] + m1[15] * m2[ 7];
    
    mout[ 8] = m1[ 0] * m2[ 8] + m1[ 4] * m2[ 9] + m1[ 8] * m2[10] + m1[12] * m2[11];
    mout[ 9] = m1[ 1] * m2[ 8] + m1[ 5] * m2[ 9] + m1[ 9] * m2[10] + m1[13] * m2[11];
    mout[10] = m1[ 2] * m2[ 8] + m1[ 6] * m2[ 9] + m1[10] * m2[10] + m1[14] * m2[11];
    mout[11] = m1[ 3] * m2[ 8] + m1[ 7] * m2[ 9] + m1[11] * m2[10] + m1[15] * m2[11];
    
    mout[12] = m1[ 0] * m2[12] + m1[ 4] * m2[13] + m1[ 8] * m2[14] + m1[12] * m2[15];
    mout[13] = m1[ 1] * m2[12] + m1[ 5] * m2[13] + m1[ 9] * m2[14] + m1[13] * m2[15];
    mout[14] = m1[ 2] * m2[12] + m1[ 6] * m2[13] + m1[10] * m2[14] + m1[14] * m2[15];
    mout[15] = m1[ 3] * m2[12] + m1[ 7] * m2[13] + m1[11] * m2[14] + m1[15] * m2[15];
}


void mat4f_CopyMat4f(const float* min, float* mout) {

	memcpy(mout, min, 16*sizeof(float));
}


void mat4f_PrintMatrix4x4( const float*a ) {

#ifdef DEBUG
	printf("%+2.3f  %+2.3f  %+2.3f  %+2.3f\n", a[ 0], a[ 1], a[ 2], a[ 3]);
	printf("%+2.3f  %+2.3f  %+2.3f  %+2.3f\n", a[ 4], a[ 5], a[ 6], a[ 7]);
	printf("%+2.3f  %+2.3f  %+2.3f  %+2.3f\n", a[ 8], a[ 9], a[10], a[11]);
	printf("%+2.3f  %+2.3f  %+2.3f  %+2.3f\n", a[12], a[13], a[14], a[15]);
#endif
}


void mat4f_PrintMatrix3x3( const float*a ) {

#ifdef DEBUG
	printf("%+2.3f  %+2.3f  %+2.3f\n", a[0], a[1], a[2]);
	printf("%+2.3f  %+2.3f  %+2.3f\n", a[3], a[4], a[5]);
	printf("%+2.3f  %+2.3f  %+2.3f\n", a[6], a[7], a[8]);
#endif
}


void mat4f_SubMatrix3x3(const float* a, float* mout) {

	/* 
     in:
      0   1   2   3
      4   5   6   7
      8   9  10  11
	 12  13  14  15
     
     out:
     0  1  2
     4  5  6
     8  9 10
	 */
	mout[0] = a[ 0];
	mout[1] = a[ 1];
	mout[2] = a[ 2];
	
	mout[3] = a[ 4];
	mout[4] = a[ 5];
	mout[5] = a[ 6];
	
	mout[6] = a[ 8];
	mout[7] = a[ 9];
	mout[8] = a[10];
}


void mat4f_MultiplyVec4f(const float* min, const float* vin, float* vout) {

	vout[ 0] = min[0] * vin[0] + min[4] * vin[1]  + min[ 8] * vin[2] + min[12] * vin[3];
    vout[ 1] = min[1] * vin[0] + min[5] * vin[1]  + min[ 9] * vin[2] + min[13] * vin[3];
    vout[ 2] = min[2] * vin[0] + min[6] * vin[1]  + min[10] * vin[2] + min[14] * vin[3];
    vout[ 3] = min[3] * vin[0] + min[7] * vin[1]  + min[11] * vin[2] + min[15] * vin[3];
}


