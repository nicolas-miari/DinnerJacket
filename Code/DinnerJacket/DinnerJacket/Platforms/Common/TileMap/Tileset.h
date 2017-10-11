//
//  Tileset.h
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-08-04.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OpenGL.h"



typedef struct tTilesetSwatch {

    /* Encapsulates the texture coordinates corresponding to one tile in the
     sheet (=brush pattern). Map layers apply these values to the vertices of 
     each layer tile.
     */
    
    GLfloat      s0;            // left texture coordinate
    GLfloat      s1;            // right texture coordinate
    GLfloat      t0;            // top texture coordinate
    GLfloat      t1;            // bottom texture coordinate
    
    char*        namePtr;       // name of brush if named
    
}TilesetSwatch;



@class DNRTexture;



/**
 */
@interface Tileset : NSObject


///
@property (nonatomic, readonly) NSString* name;

///
@property (nonatomic, readonly) NSString* imageFilePath;

///
@property (nonatomic, readonly) TilesetSwatch* palette;

///
@property (nonatomic, readonly) NSUInteger paletteSize;

///
@property (nonatomic, strong, readwrite) DNRTexture* texture;


/**
 */
- (instancetype) initWithImageNamed:(NSString *)imageName
                        inDirectory:(NSString *)directoryPath
                           tileSize:(NSUInteger) tileSize
                            palette:(NSArray *)palette;


/** 
 Used by symbolic map layers to convert brush index into object on 
 initialization.
 */
- (NSString *)mapObjectIdentifierForBrushIndex:(NSUInteger) brushIndex;

@end
