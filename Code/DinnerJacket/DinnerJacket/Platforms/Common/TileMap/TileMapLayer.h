//
//  TileMapLayer.h
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-08-04.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import "DNRNode.h"
#import "Tileset.h"



@class TileMap;



/**
 */
@interface TileMapLayer : DNRNode


///
@property (nonatomic, readonly) CGFloat scrollFactor;


/// Symbolic layers are scrollable placeholders for map objects; they do not
/// perform drawing. This flag causes the deferred assignment of a VAO to be
/// skipped.
@property (nonatomic, readwrite, getter=isSymbolic) BOOL symbolic;


/**
 */
- (instancetype) initWithContentsOfDictionary:(NSDictionary *)dictionary
                              forUseInTileMap:(TileMap *)tileMap;

/**
 */
- (void) createVertexArrayObject;

@end
