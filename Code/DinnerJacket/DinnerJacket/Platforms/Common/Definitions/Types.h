//
//  Geometry.h
//  DinnerJacket
//
//  Created by Nicolás Miari on 2016/09/10.
//  Copyright © 2016 Nicolás Miari. All rights reserved.
//

#ifndef Types_h
#define Types_h

#include "OpenGL.h"


/**
 2D Vector used for specifying the texture coordinate data of one vertex.
 */
typedef struct tTextureCoordinates {
    GLfloat s;
    GLfloat t;
} TextureCoordinates;


/**
 2D Vector used for specifying postion data of one vertex.
 */
typedef struct tVertex2f {
    GLfloat x;
    GLfloat y;
} Vertex2f, Vector2f;

/**
 3D Vector used for specifying postion data of one vertex.
 */
typedef struct tVertex3f {
    GLfloat x;
    GLfloat y;
    GLfloat z;
} Vertex3f, Vector3f;


/**
 4D Vector used for specifying postion data of one vertex.
 */
typedef struct tVertex4f {
    GLfloat x;
    GLfloat y;
    GLfloat z;
    GLfloat w;
} Vertex4f, Vector4f;


/**
 4D vector used for specifying color data of one vertex, in RGBA (unsigned 
 byte) format.
 */
typedef  struct tColor4ub {
    GLubyte r;
    GLubyte g;
    GLubyte b;
    GLubyte a;
} Color4ub;


/**
 4D vector used for specifying color data of one vertex, in RGBA (float) format.
 */
typedef struct tColor4f {
    GLfloat r;
    GLfloat g;
    GLfloat b;
    GLfloat a;
} Color4f;


/**
 Encapsulates all attributes for one vertex of a 3D object.
 */
typedef struct tVertexData3D {

    Vertex3f                position;
    Vertex3f                normal;
    TextureCoordinates      texCoords;
    Color4f                 color;
} VertexData3D;


/**
 Encapsulates all attributes for one vertex of a 2D sprite.
 */
typedef struct tVertexData2D {
    Vertex2f                position;
    TextureCoordinates      texCoords;
} VertexData2D;


/**
 Creates an instance of Color4f from the given components. Akin to CGRectMake() etc.
 */
static inline Color4f Color4fMake(GLfloat r, GLfloat g, GLfloat b, GLfloat a) {
    Color4f color;
    color.r = r;
    color.g = g;
    color.b = b;
    color.a = a;

    return color;
}


/** 
 Blends two colors proportionally.
 */
static inline Color4f Color4fInterpolate(Color4f color1, Color4f color2, GLfloat ratio) {
    // ratio == 0.0 -> (color1         )
    // ratio == 0.5 -> (color1 + color2) / 2
    // ratio == 1.0 -> (         color2)
    
    ratio = (ratio > 1.0) ? 1.0 : (ratio < 0.0 ? 0.0 : ratio);
    
    GLfloat invRatio = 1.0 - ratio;
    
    Color4f color;
    
    color.r = invRatio*color1.r + ratio*color2.r;
    color.g = invRatio*color1.g + ratio*color2.g;
    color.b = invRatio*color1.b + ratio*color2.b;
    color.a = invRatio*color1.a + ratio*color2.a;
    
    return color;
}

// Some convenient constants:

#define Color4fWhite   Color4fMake(1.0, 1.0, 1.0, 1.0)
#define Color4fBlack   Color4fMake(0.0, 0.0, 0.0, 1.0)
#define Color4fRed     Color4fMake(1.0, 0.0, 0.0, 1.0)
#define Color4fGreen   Color4fMake(0.0, 1.0, 0.0, 1.0)
#define Color4fBlue    Color4fMake(0.0, 0.0, 1.0, 1.0)
#define Color4fCyan    Color4fMake(0.0, 1.0, 1.0, 1.0)
#define Color4fMagenta Color4fMake(1.0, 0.0, 1.0, 1.0)
#define Color4fYellow  Color4fMake(1.0, 1.0, 0.0, 1.0)


#endif /* Types_h */
