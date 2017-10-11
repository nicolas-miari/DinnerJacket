//
//  TileMap.h
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-08-04.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import "DNRNode.h"



@class TileMap;

@class Tileset;



/** 
 @brief Protocol adopted by the object responsible for providing map objects
        (game objects) to populate the tile map.
 
 @details
        The map's symbolic layers contain references to map objects (display 
    hierarchy node subclasses) to be instantiated and placed on the map on 
    initialization. These are specified inside the map file as strings. The data
    source is responsible for deciding which class to instantiate based on that
    string, and provide the instance to the map for placement inside the display 
    hierarchy.
 */
@protocol TileMapDataSource <NSObject>

/**
 @brief Sent zero or more times during asynchronous initialization to populate 
        each map layer.
 
 @details
        During map layer initialization, placement information for map objects 
    is read from file. This information consists of an initial position in the 
    layer and an application-specific string (identifier) used to determine 
    which kind of object (e.g. player, coin, enemy, etc.) it should be. The map 
    layer is thus populated with such objects, instantiated and provided on
    demand by the data source.
 */
- (DNRNode *)instanceOfMapObjectWithIdentifier:(NSString *)identifier;


@end


/**
 @interface TileMap
 
 */
@interface TileMap : DNRNode


/// Object that provides game objects to populate the map's container (symbolic)
/// layers.
@property (nonatomic, readonly, weak) id<TileMapDataSource> dataSource;


/// Width and height of each map layer's grid, as a number of tiles wide and
/// high (all layers on the same map must have the same grid size).
@property (nonatomic, readonly) CGSize  layerSize;


/// Size, in points, of the side of one (square) map tile.
@property (nonatomic, readonly) NSUInteger tileSize;


/**
 Instantiates the tile map object and specifies the object that will provide
 map object instances (the data source). The actual map data (tiles) is not
 created until `-beginAsyncLoadingWithCompletionHandler:` is called.
 */
- (instancetype) initWithDictionary:(NSDictionary *)dictionary
                         dataSource:(id<TileMapDataSource>) dataSource;


/**
 Initializes all resources associated with the tile map (geometry, bitmap data)
 using a background thread and associated secondary graphics context whenever 
 possible. On completion, the `completionHandler` block is executed. At that 
 point, the tile map is ready to be displayed on screen.
 */
- (void) beginAsyncLoadingWithCompletionHandler:(void (^)(void)) completionHandler;


/**
 */
- (Tileset *)tilesetNamed:(NSString *)tilesetName;


@end
