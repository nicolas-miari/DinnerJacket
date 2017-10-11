//
//  DNRGlobals.c
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-03-08.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#include <stdio.h>
#include <stddef.h>

#include "DNRGlobals.h"


// 2D Vertex Format

GLsizei stride2D            = (GLsizei) (sizeof(VertexData2D));
GLvoid* positionOffset2D    = (GLvoid *)0;                      // VertexData2D - Offset into position
GLvoid* textureOffset2D     = (GLvoid *)(sizeof(Vertex2f));     // VertexData2D - Offset into texCoords


// 3D Vertex Format

GLsizei stride3D            = (GLsizei) (sizeof(VertexData3D));
GLvoid* positionOffset3D    = (GLvoid *)(offsetof(VertexData3D, position));     //(GLvoid*)(0);
GLvoid* normalOffset3D      = (GLvoid *)(offsetof(VertexData3D, normal));       //(GLvoid*)(1*sizeof(Vertex3D));
GLvoid* textureOffset3D     = (GLvoid *)(offsetof(VertexData3D, texCoords));    //(GLvoid*)(2*sizeof(Vertex3D));


float   screenScaleFactor         = 1.0f;

