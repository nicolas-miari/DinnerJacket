//
//  TileMapLayer.m
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-08-04.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import "TileMapLayer.h"

#import "Tileset.h"

#import "TileMap.h"

#import "DNRTexture.h"

#import "DNRShaderManager.h"
#import "DNRGLCache.h"

#import "DNRGlobals.h"          // Stride, etc.



typedef struct tLayerTile {

    GLfloat     x;
    GLfloat     y;
    
    //BOOL        flipX;
    //BOOL        flipY;

}LayerTile;



static GLuint       program                     = 0u;

static GLint        positionLocation            = -1;
static GLint        textureCoordinateLocation   = -1;

static GLint        colorLocation               = -1;
static GLint        samplerLocation             = -1;
static GLint        modelviewLocation           = -1;
static GLint        zLocation                   = -1;


// Layer
static NSString* const kTileMapLayerNameKey           = @"Name";
static NSString* const kTileMapLayerNameBlendedSuffix = @"(Blended)";
static NSString* const kTileMapLayerNonOpaqueKey      = @"NeedsBlending";
static NSString* const kTileMapLayerScrollFactorKey   = @"ScrollFactor";
static NSString* const kTileMapLayerTilesetNameKey    = @"TilesetName";
static NSString* const kTileMapLayerTilesKey          = @"Tiles";
static NSString* const kTileMapLayerMapObjectsKey     = @"Objects";

// Mesh tile
static NSString* const kTilePaletteIndexKey         = @"PaletteIndex";
static NSString* const kTilePositionKey             = @"Position";
static NSString* const kTileHorizontalReflectionKey = @"FlipX";
static NSString* const kTileVerticalReflectionKey   = @"FlipY";

// Map Object
static NSString* const kObjectLibraryIndexKey = @"Index";
static NSString* const kObjectPositionKey     = @"Position";


// .............................................................................

@interface TileMapLayer ()

@property (nonatomic, readwrite) Tileset*      tileset;
@property (nonatomic, readwrite) CGSize        layerSize;
@property (nonatomic, readwrite) GLuint        textureName;
@property (nonatomic, readwrite) void***       objectGrid;
@property (nonatomic, readwrite) VertexData2D* vertices;
@property (nonatomic, readwrite) GLsizei       vertexCount;
@property (nonatomic, readwrite) GLushort*     indices;
@property (nonatomic, readwrite) GLsizei       indexCount;
@property (nonatomic, readwrite) GLuint        vbo;
@property (nonatomic, readwrite) GLuint        ibo;
@property (nonatomic, readwrite) GLuint        vao;

@property (nonatomic, readwrite, getter=isHidden) BOOL hidden;

@end


// .............................................................................


@implementation TileMapLayer


#pragma mark - Static Methods

/**
 Initialize resources shared among all instances of the class.
 */
+ (void) initialize {

    if (self == [TileMapLayer class]) {
        
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            
            program = [[DNRShaderManager defaultManager] spriteProgram];
            
            positionLocation            = glGetAttribLocation(program, "Position");
            textureCoordinateLocation   = glGetAttribLocation(program, "TextureCoord");
            
            colorLocation       = glGetUniformLocation(program, "Color");
            samplerLocation     = glGetUniformLocation(program, "Sampler");
            modelviewLocation   = glGetUniformLocation(program, "Modelview");
            zLocation           = glGetUniformLocation(program, "Z");
        });
    }
}


#pragma mark - Initialization

/**
 Symbolic Layer Initialization:
 
 Instantiate map objects and place. Cache in 2D array for quick access and
 proximity evaluation.
 
 
 Graphic Layer initialization:
 
 [1]
 Generate 4n Vertices, where n is the number of tiles, at the appropriate
 positions/tex coords.
 
 [2]
 Begin with a tentative ammount of indices of 4n (one per vertex);
 neighbouring quads yield the necessary degenerate triangles as is.
 for each gap between successive quads, add 2 indices to the total.
 Allocate index array.
 
 [3]
 Finally, Initialize indices.
 Parse one quad at a time. Add each vertex to the index array in turn.
 IF the next quad is not adjascent horizontally, add two extra indices:
 repeat the last vertex of the quad and the first index of the next quad.
 Proceed to next quad...
 */
- (instancetype) initWithContentsOfDictionary:(NSDictionary *)dictionary
                              forUseInTileMap:(TileMap *)tileMap {

    if (self = [super init]) {
        
        // Basic attributes:
        self.localizedName = [[dictionary objectForKey:kTileMapLayerNameKey] copy];
        _scrollFactor  = [[dictionary objectForKey:kTileMapLayerScrollFactorKey] floatValue];
        _tileset       = [tileMap tilesetNamed:[dictionary objectForKey:kTileMapLayerTilesetNameKey]];

        _layerSize     = [tileMap layerSize];
        
        if ([[self localizedName] isEqualToString:@"Trampolins(Symbolic)"]){
            
        }
        
        // Tile Mesh
        NSArray* tileDictionaries = dictionary[kTileMapLayerTilesKey];
        
        if (tileDictionaries){
            [self createMeshWithTiles:tileDictionaries forUseInTileMap:tileMap];
            self.needsBlending = [[dictionary objectForKey:kTileMapLayerNonOpaqueKey] boolValue];
        }
        else{
            _symbolic = YES;
        }
        
        // Map Objects
        NSArray* objectDictionaries = dictionary[kTileMapLayerMapObjectsKey];
        
        if (objectDictionaries){
            [self loadMapObjects:objectDictionaries fromMap:tileMap];
        }
    }
    
    return self;
}


/**
 Build the geometry to render (if present)
 */
- (void) createMeshWithTiles:( NSArray* __nonnull) tileDictionaries
             forUseInTileMap:(TileMap *)tileMap {

    _textureName   = [[_tileset texture] name];
    
    // metrics
    CGSize     sizeInTiles  = [tileMap layerSize];   // How many tiles wide and high
    NSUInteger tileSize     = [tileMap tileSize];    // How many points is the square tile side
    GLfloat    halfTileSize = 0.5f * tileSize;       // Half of it (to avoid multiple calculations after)
    GLfloat    layerWidth   = sizeInTiles.width  * tileSize; // Width of layer/map, in points
    GLfloat    layerHeight  = sizeInTiles.height * tileSize; // Width of layer/map, in points
    
    // Center of the top-left tile:
    GLfloat left = (-0.5f * layerWidth ) + halfTileSize;
    GLfloat top  = (+0.5f * layerHeight) - halfTileSize;
    
    // The actual number of tiles is normally much less than that of grid cells
    // (map width x map height), typically much less, because the mesh is sparse
    // (not all grid cells are "painted").
    int tileCount = (int)[tileDictionaries count];
    
    LayerTile* layerTiles = calloc(sizeof(LayerTile), tileCount);
    
    TilesetSwatch* palette = [_tileset palette];
    NSUInteger paletteSize = [_tileset paletteSize];
    
    
    _vertexCount = 4*tileCount; // One quad per tile
    _vertices = calloc(sizeof(VertexData2D), _vertexCount);
    
    NSUInteger tileIndex    = 0; // indexes array layerTiles[]
    NSUInteger vertexIndex  = 0; // indexes array _vertices[]
    NSUInteger paletteIndex = 0; // indexes array palette[]
    
    BOOL flipX = false;
    BOOL flipY = false;
    
    GLfloat s0, s1, t0, t1;
    
    // Draw...
    
    for (NSDictionary* tileDictionary in tileDictionaries) {
        
        // ...What (which subregion of the texture):
        paletteIndex = [[tileDictionary objectForKey:kTilePaletteIndexKey] unsignedIntegerValue];
        
        // ...Where (in the layer grid):
        CGPoint gridPosition = CGPointFromString([tileDictionary objectForKey:kTilePositionKey]);
        
        // ...How (vertical and horizontal reflection):
        flipX = [[tileDictionary objectForKey:kTileHorizontalReflectionKey] boolValue];
        flipY = [[tileDictionary objectForKey:kTileVerticalReflectionKey] boolValue];
        
        
        layerTiles[tileIndex].x = gridPosition.x;
        layerTiles[tileIndex].y = gridPosition.y;
        // (used later to calculate index array)
        
        if (paletteIndex >= paletteSize) { // Error! - For now, use first pattern:
            paletteIndex = 0;
        }
        
        // 2. Configure actual vertex data
        
        // Index of first vertex of the tile, in _vertices[]:
        vertexIndex = 4 * tileIndex;
        
        // Position of current tile's center:
        GLfloat cx = left + (gridPosition.x * tileSize);
        GLfloat cy = top  - (gridPosition.y * tileSize);
        
        // X and Y coordinates of the four vertices:
        GLfloat x0 = (cx - halfTileSize) * screenScaleFactor; // (Coords are in pixels)
        GLfloat x1 = (cx + halfTileSize) * screenScaleFactor;
        GLfloat y0 = (cy + halfTileSize) * screenScaleFactor;
        GLfloat y1 = (cy - halfTileSize) * screenScaleFactor;
        
        // (We achieve horizontal and/or vertical reflection by swapping texture
        // coordinates among the four vertices of the quad:)
        
        if (flipX) { // Reflect Horizontally
            s0 = palette[paletteIndex].s1;
            s1 = palette[paletteIndex].s0;
        }
        else{
            s0 = palette[paletteIndex].s0;
            s1 = palette[paletteIndex].s1;
        }
        
        if (flipY) { // Reflect Vertically
            t0 = palette[paletteIndex].t1;
            t1 = palette[paletteIndex].t0;
        }
        else{
            t0 = palette[paletteIndex].t0;
            t1 = palette[paletteIndex].t1;
        }
        
        _vertices[vertexIndex].position.x  = x0;    // (Top-Left Vertex)
        _vertices[vertexIndex].position.y  = y0;
        _vertices[vertexIndex].texCoords.s = s0;
        _vertices[vertexIndex].texCoords.t = t0;
        vertexIndex++;
        
        _vertices[vertexIndex].position.x  = x0;    // (Bottom-Left Vertex)
        _vertices[vertexIndex].position.y  = y1;
        _vertices[vertexIndex].texCoords.s = s0;
        _vertices[vertexIndex].texCoords.t = t1;
        vertexIndex++;
        
        _vertices[vertexIndex].position.x  = x1;    // (Top-Right Vertex)
        _vertices[vertexIndex].position.y  = y0;
        _vertices[vertexIndex].texCoords.s = s1;
        _vertices[vertexIndex].texCoords.t = t0;
        vertexIndex++;
        
        _vertices[vertexIndex].position.x  = x1;    // (Bottom-Right Vertex)
        _vertices[vertexIndex].position.y  = y1;
        _vertices[vertexIndex].texCoords.s = s1;
        _vertices[vertexIndex].texCoords.t = t1;
        
        // Next tile:
        tileIndex++;
    }
    
    
    // Configure index array
    
    // Start with one index per vertex, at least:
    _indexCount = _vertexCount;
    
    // 1. First pass: count 'gaps' between adjascent tiles in order to calculate
    //    the total number of indices needed.
    
    LayerTile* pThisTile = NULL;
    LayerTile* pNextTile = NULL;
    
    BOOL tilesAreOnSameRow       = false;
    BOOL tilesAreOneColumnAppart = false;
    
    for (NSUInteger i = 0; i < tileCount - 1; i++) { // Loop all tiles except last
        
        pThisTile = &(layerTiles[  i  ]); // Current tile
        pNextTile = &(layerTiles[i + 1]); // next tile
        
        // Test for tile adjascency:
        tilesAreOnSameRow       = ( pThisTile->y      == pNextTile->y );
        tilesAreOneColumnAppart = ((pThisTile->x + 1) == pNextTile->x );
        
        if (tilesAreOnSameRow && tilesAreOneColumnAppart) {
            // Tiles are contiguous; No special treatment.
        }
        else{
            // There is a gap between the two tiles; Add two extra indices to
            // account for a degenerate triangle:
            _indexCount += 2;
        }
    }
    
    _indices = calloc(sizeof(GLushort), _indexCount);
    
    
    // 2. Second pass: Calculate actual indices
    
    // Keeps track of at which position of the index array we are writing to
    NSUInteger slot = 0;
    
    // Holds the index, in the vertex array, of the first vertex of the current tile
    NSUInteger indexOfFirstVertex;
    
    for (NSUInteger i = 0; i < tileCount - 1; i++) { // Loop all tiles except last
        
        pThisTile = &(layerTiles[  i  ]);
        pNextTile = &(layerTiles[i + 1]);
        
        // Set the indices that point to the 4 vertices of the current tile:
        
        indexOfFirstVertex = 4*i; // (Four vertices per tile, so starts at a 4-boundary)
        
        _indices[slot    ] = indexOfFirstVertex;
        _indices[slot + 1] = indexOfFirstVertex + 1;
        _indices[slot + 2] = indexOfFirstVertex + 2;
        _indices[slot + 3] = indexOfFirstVertex + 3;
        
        // Conditions for tile adjascency:
        tilesAreOnSameRow       = ( pThisTile->y      == pNextTile->y );
        tilesAreOneColumnAppart = ((pThisTile->x + 1) == pNextTile->x );
        
        if (tilesAreOnSameRow && tilesAreOneColumnAppart) {
            // Tiles are contiguous; Move the 'writing head' forward by just
            // the FOUR vertices we wrote:
            slot += 4;
        }
        else{
            // The is a gap between the tiles; Repeat index of current tile's
            // last vertex:
            _indices[slot + 4] = indexOfFirstVertex + 3;
            
            // Repeat index of next tile's first vertex:
            _indices[slot + 5] = indexOfFirstVertex + 4;
            
            // Move writing head forward by the two extra vertices we just wrote:
            slot += 6;
        }
    }
    
    // Indices for last tile:
    _indices[_indexCount - 4] = _vertexCount - 4;
    _indices[_indexCount - 3] = _vertexCount - 3;
    _indices[_indexCount - 2] = _vertexCount - 2;
    _indices[_indexCount - 1] = _vertexCount - 1;
    
    free(layerTiles);
    
    // (Next: Initialize OpenGL ES Objects on main thread)
}


/**
 */
- (void) loadMapObjects:(NSArray *)objectDictionaries fromMap:(TileMap *)tileMap {

    // metrics
    CGSize     sizeInTiles  = [tileMap layerSize];   // How many tiles wide and high
    NSUInteger tileSize     = [tileMap tileSize];    // How many points is the square tile side
    GLfloat    halfTileSize = 0.5f * tileSize;       // Half of it (to avoid multiple calculations after)
    GLfloat    layerWidth   = sizeInTiles.width  * tileSize; // Width of layer/map, in points
    GLfloat    layerHeight  = sizeInTiles.height * tileSize; // Width of layer/map, in points
    
    // Center of the top-left tile:
    GLfloat left = (-0.5f * layerWidth ) + halfTileSize;
    GLfloat top  = (+0.5f * layerHeight) - halfTileSize;
    
    NSUInteger rowCount    = sizeInTiles.height;
    NSUInteger columnCount = sizeInTiles.width;
    
    _objectGrid = calloc(sizeof(void**), rowCount);
    for (NSUInteger j = 0; j < rowCount; j++) {
        _objectGrid[j] = calloc(sizeof(void*), columnCount);
    }
    
    id<TileMapDataSource> mapDelegate = [tileMap dataSource];
    
    
    for (NSDictionary* tileDictionary in objectDictionaries) {
        
        NSUInteger index      = [[tileDictionary objectForKey:kTilePaletteIndexKey] unsignedIntegerValue];
        NSString*  identifier = [_tileset mapObjectIdentifierForBrushIndex:index];
        
        if (identifier) {
            // Instantiate object and place
            
            DNRNode* mapObject = [mapDelegate instanceOfMapObjectWithIdentifier:identifier];
            
            if (mapObject == nil) {
                continue;
            }
            
            CGPoint position = CGPointFromString([tileDictionary objectForKey:kTilePositionKey]);
            
            NSUInteger x = position.x;
            NSUInteger y = position.y;
            
            CGPoint objectPosition = CGPointMake(left + x*tileSize,
                                                 top - y*tileSize);
            
            [mapObject setPosition:objectPosition];
            [self addChild:mapObject];
            
            
            // Insert into C-style 2D array (for quick access):
            _objectGrid[y][x] = (__bridge void *)(mapObject);
        }
    }
}


- (void) dealloc {

    if (_objectGrid != NULL) {
    
        // 1. Free each row:
        for (NSUInteger j = 0; j < _layerSize.height; j++){
            free(_objectGrid[j]);
        }
        
        // 2. Free array of rows:
        free(_objectGrid);
    }
}


- (void) createVertexArrayObject {

    /*
     IMPORTANT: THIS METHOD MUST RUN ON THE MAIN THREAD.
     Vertex Array Objects can not be shared among different OpenGL contexts.
     */
    
    NSAssert([NSThread isMainThread], @"ERROR: This method must be executed on the main thread");
    
    bindVertexBufferObject(0);
    bindIndexBufferObject(0);
    
    // Create and bind a VAO
    glGenVertexArrays(1, &_vao);
    bindVertexArrayObject(_vao);
    
    // Create and bind a BO for vertex data
    glGenBuffers(1, &_vbo);
    bindVertexBufferObject(_vbo);
    
    // copy data into the buffer object
    glBufferData(GL_ARRAY_BUFFER,
                 _vertexCount*sizeof(VertexData2D),
                 &_vertices[0],
                 GL_STATIC_DRAW);
    
    // Create and bind a BO for index data
    glGenBuffers(1, &_ibo);
    bindIndexBufferObject(_ibo);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER,
                 _indexCount*sizeof(GLushort),
                 &_indices[0],
                 GL_STATIC_DRAW);
    
    // set up vertex attributes
    glEnableVertexAttribArray(positionLocation);
    glEnableVertexAttribArray(textureCoordinateLocation);
    
    glVertexAttribPointer(positionLocation, 2, GL_FLOAT, GL_FALSE, stride2D, positionOffset2D);
    glVertexAttribPointer(textureCoordinateLocation, 2, GL_FLOAT, GL_FALSE, stride2D, textureOffset2D);
    
    
    /*
     At this point the VAO is set up with two vertex attributes referencing the 
     same buffer object, and another buffer object as source for index data. We 
     can now unbind the VAO, go do something else, and bind it again later when 
     we want to render with it.
     */
    bindVertexArrayObject(0);
    
    glDisableVertexAttribArray(positionLocation);
    glDisableVertexAttribArray(textureCoordinateLocation);
    
    
    // Unbind VBO/IBO too
    bindIndexBufferObject(0);
    bindVertexBufferObject(0);
}



#pragma mark - Superclass Method Overrides


- (BOOL) drawsSelf {
    return (!_symbolic && !_hidden);
}


- (void) render {

    // (called only on instances that return YES from -drawsSelf. (i.e.,
    // instances with a mesh to display, not just map object placeholders)
    
    static GLfloat  colorVector[4] = { 1.0f, 1.0f, 1.0f, 1.0f };
    static GLfloat* modelview      = NULL;
    
    modelview = [self worldTransform];
    
    CGFloat alpha = [self alpha];
    
    colorVector[0] = alpha;
    colorVector[1] = alpha;
    colorVector[2] = alpha;
    colorVector[3] = alpha;

    
    useProgram(program);                       // Cached - calls glUseProgram(_program) if necessary
    bindTexture2D(_textureName);               // Cached - calls glBundTexture(GL_TEXTURE_2D, _textureName) if necessary
    uniform4fv(colorLocation, colorVector);    // Cached - calls glUniform4fv(colorLocation, colorVector) if necessary
    uniform1f(zLocation, [self z]);            // Cached - calls glUniform4fv(zLocation, [self z]) if necessary
    
    glUniformMatrix4fv(modelviewLocation, 1, 0, modelview);
    
    bindVertexArrayObject(_vao);               // Cached - calls glBindVertexArrayOES(_vao) if necessary
    
    glDrawElements(GL_TRIANGLE_STRIP, _indexCount, GL_UNSIGNED_SHORT, 0);
    
    bindVertexArrayObject(0);
}


@end
