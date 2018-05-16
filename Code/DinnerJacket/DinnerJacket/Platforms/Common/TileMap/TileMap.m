//
//  TileMap.m
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-08-04.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import "TileMap.h"             // (own header)
#import "Platform.h"
#import "Tileset.h"             // Child object
#import "TileMapLayer.h"        // Child object
#import "DNRTexture.h"
#import "Platform.h"
#import "CGSupport.h"

#import "DNRSceneController.h"  // App diagnostics

#ifdef DNRPlatformPhone
#import "../../iOS/ViewController/DNRViewController.h"
#else
#import "../../macOS/ViewController/DNRViewController.h"
#endif


static NSString* const kTileMapTileSizeKey  = @"TileSize";
static NSString* const kTileMapLayerSizeKey = @"LayerSize";
static NSString* const kTileMapTilesetsKey  = @"Tilesets";
static NSString* const kTileMapLayersKey    = @"Layers";

/* For maps bundled as a resource with the app, this field is nil. For 
    downloaded maps, it is the path to the base directory (where the .plist 
    resides), relative to the app sandbox (e.g. Documents/Maps/01/).
 */
static NSString* const  kTileMapBaseDirectoryPathKey =    @"BaseDirectory";


// .............................................................................

@interface TileMap ()

@property (nonatomic, readwrite, weak) id <TileMapDataSource> dataSource;
@property (nonatomic, readwrite) NSString* baseDirectoryPath;
@property (nonatomic, readwrite) NSDictionary* sourceDictionary;
@property (nonatomic, readwrite) NSMutableDictionary* tilesetsByName;
@property (nonatomic, readwrite) NSMutableDictionary* mapLayersByName;
@property (nonatomic, readwrite) NSMutableArray* mapLayersInStackingOrder; // bottom to top
@property (nonatomic, readwrite) CGFloat xMin;
@property (nonatomic, readwrite) CGFloat xMax;
@property (nonatomic, readwrite) CGFloat yMin;
@property (nonatomic, readwrite) CGFloat yMax;

@end


// .............................................................................


@implementation TileMap


- (instancetype) initWithDictionary:(NSDictionary *)dictionary
                           dataSource:(id<TileMapDataSource>) dataSource {

    if (self = [super init]) {

        // Keep dictionary for later background loading:
        _sourceDictionary = [dictionary copy];
        
        // During loading of map layers, data source provides actual instances
        // for all map objects specified on file:
        _dataSource = dataSource;
        
        // Read basic attributes right away:
        _tileSize = [[dictionary objectForKey:kTileMapTileSizeKey] unsignedIntegerValue];
        _layerSize = CGSizeFromString([dictionary objectForKey:kTileMapLayerSizeKey]);
        
        
        // Calculate limits for map position:
        CGSize screenSize = [[DNRViewController sharedController] screenSize];
        CGSize pointSize  = CGSizeMake(_tileSize*(_layerSize.width), _tileSize*_layerSize.height);
        
        _xMax = (pointSize.width - screenSize.width) / 2.0f;
        _yMax = (pointSize.height - screenSize.height) / 2.0f;
        _xMin = -_xMax;
        _yMin = -_yMax;
        
        // (the rest is loaded/initialized asynchronously)
    }
    
    return self;
}


#pragma mark - Initialization


- (void) beginAsyncLoadingWithCompletionHandler:(void (^)(void)) completionHandler {

    /*
     Perform the following actions in a background thread (asynchronously):
     (1) Load all Tilesets (with their textures) one by one. On completion,
     (2) Allocate and initialize all map layers (map objects included), but stop
     short of creating the actual vertex array objects (these can't be shared
     among OpenGL ES context). On completion, go back to main thread and:
     (3) Create the vertex array objects for all layers, one by one. On 
     completion, notify listener.
     */
    
    NSAssert(completionHandler, @"Error: Completion Handler Can't Be NULL");
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(){
        // ===================== BEGIN BACKGROUND THREAD =======================
       
        // [ 0 ] Switch to dedicated (background) graphics context:

        #ifdef DNRPlatformPhone     
        // iOS (OpenGL ES)
        EAGLContext* backgroundContext = [[DNRViewController sharedController] backgroundRenderingContext];
        [EAGLContext setCurrentContext:backgroundContext];
        #else                       
        // macOS (OpenGL)
        NSOpenGLContext* backgroundContext = [[DNRViewController sharedController] backgroundRenderingContext];
        [backgroundContext makeCurrentContext];
        #endif
        
        
        // [ 1 ] Load all tilesets

       self.tilesetsByName = [NSMutableDictionary new];
       
        NSDictionary* tilesetDictionariesByName = self.sourceDictionary[kTileMapTilesetsKey];
        
        for (NSString* tilesetName in [tilesetDictionariesByName allKeys]){
            
            NSDictionary* tilesetDictionary = tilesetDictionariesByName[tilesetName];
            NSArray* paletteArray = tilesetDictionary[@"Palette"];
            
            Tileset* tileset = [[Tileset alloc] initWithImageNamed:tilesetName
                                                       inDirectory:nil
                                                          tileSize: self.tileSize
                                                           palette:paletteArray];
            
            self.tilesetsByName[tilesetName] = tileset;
        }
                                                   
       
       
       // [ 2 ] Create map layers (minus VAO):
       
        self->_mapLayersByName  = [NSMutableDictionary new];
        self->_mapLayersInStackingOrder = [NSMutableArray new];
       
        for (NSDictionary* layerDictionary in self->_sourceDictionary[kTileMapLayersKey]) {
           
           TileMapLayer* layer = [[TileMapLayer alloc] initWithContentsOfDictionary:layerDictionary
                                                                    forUseInTileMap:self];
           
           [self->_mapLayersInStackingOrder addObject:layer];
           
           NSString* layerName = [layer localizedName];
           
           [self->_mapLayersByName setObject:layer forKey:layerName];
       }
       
       
       // 3. Create VAOs for all map layers, and add them to display hierarchy:
       
       dispatch_async( dispatch_get_main_queue(), ^{
           
           // ********************** BEGIN MAIN THREAD *************************
           
           // Vertex Array Objects can not be shared among openGL ES contexts.
           // Therefore, they can not be created on  a background thread
           // (background context) if they are going to be used on the main
           // thread (main context).
           
           for (TileMapLayer* layer in self->_mapLayersInStackingOrder) {
               
               if ([layer isSymbolic] == NO){
                   [layer createVertexArrayObject];
               }
               [self addChild:layer];
           }
           
           
           // Done loading tile map; notify the listener:
           completionHandler();
           
           // *********************** END MAIN THREAD **************************
        });
        // ====================== END BACKGROUND THREAD ========================
    });
}


#pragma mark - Operation


- (Tileset *)tilesetNamed:(NSString *)tilesetName {

    if (!tilesetName) {
        return nil;
    }
    
    return [_tilesetsByName objectForKey:tilesetName];
}


- (void) setPosition:(CGPoint) position {

    // Constrain
    
    CGPoint constrainedPosition = CGPointMake(position.x, position.y);
    
    if (constrainedPosition.x < _xMin) {
        constrainedPosition.x = _xMin;
    }
    else if (constrainedPosition.x > _xMax) {
        constrainedPosition.x = _xMax;
    }
    
    if (constrainedPosition.y < _yMin) {
        constrainedPosition.y = _yMin;
    }
    else if (constrainedPosition.y > _yMax) {
        constrainedPosition.y = _yMax;
    }
    
    constrainedPosition.x = roundf(constrainedPosition.x);
    constrainedPosition.y = roundf(constrainedPosition.y);
    
    // Apply
    [super setPosition:constrainedPosition];
    
    
    // Parallax of layers:
    for (TileMapLayer* layer in _mapLayersInStackingOrder) {
        
        CGFloat speed = [layer scrollFactor];
        
        CGPoint layerPosition = CGPointMake((speed - 1.0)*(constrainedPosition.x),
                                            (speed - 1.0)*(constrainedPosition.y));
        
        // Make pixel aligned (avoids artifacts?)
        layerPosition.x = roundf(layerPosition.x);
        layerPosition.y = roundf(layerPosition.y);
        
        [layer setPosition:layerPosition];
    }
}


@end
