//
//  Tileset.m
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-08-04.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import "Tileset.h"

#import "DNRTexture.h"



static NSString* const kTilesetPaletteKey            = @"Palette";
static NSString* const kTilesetBrushIndexKey         = @"Index";
static NSString* const kTilesetBrushClassKey         = @"Class";
static NSString* const kTilesetBrushNeedsBlendingKey = @"NeedsBlending";



@implementation Tileset {

    // Set on instance initialization:
    
    NSString*       _imageName;
    NSString*       _imageDirectoryPath;
    NSDictionary*   _brushDictionary;
    NSUInteger      _tileSize;
    
    
    // Set once texture loads:
    
    DNRTexture*         _texture;
    NSUInteger          _tilesWide;
    NSUInteger          _tilesHigh;
    
    // C array of texcoord patterns for each tile (brush)
    TilesetSwatch* _palette;
    
    
    // Database of named brushes
    NSMutableDictionary* _namedBrushes;
}



- (instancetype) initWithImageNamed: (NSString *)imageName
                        inDirectory:(NSString *)directoryPath
                           tileSize:(NSUInteger) tileSize
                            palette:(NSArray *)paletteEntries {

    NSAssert(([NSThread isMainThread] == NO), @"Error: Tilesets Must Be Created On A Background Thread!");
    
    if (self = [super init]) {
        
        _imageName          = [imageName copy];
        _imageDirectoryPath = [directoryPath copy];
        _brushDictionary    = [paletteEntries copy];
        
        _tileSize = tileSize;
        
        // Texture
        NSString* textureImagePath = [self imageFilePath];
        
        // Load in synchronously (we are already in a background thread)
        _texture = [DNRTexture textureWithContentsOfFile:textureImagePath options:nil];
        
        [_texture aquire];
        
        
        // Brush data
        [self createPalette];
    }
    
    return  self;
}



- (void) dealloc {

    [self destroyPalette];
}


- (void) destroyPalette {

    if (_palette) {
        
        NSUInteger tileCount = _tilesWide*_tilesHigh;
        
        // Release string buffers
        for (NSUInteger i = 0; i < tileCount; i++) {

            if (_palette[i].namePtr != NULL) {
                free(_palette[i].namePtr);
            }
        }
        
        // Release array
        free(_palette);
        _palette = NULL;
    }
}


- (void) createPalette {

    /* Assumes texture has already been loaded
     */
    
    if (_palette || !_texture) {
        return;
    }
    
    CGSize imageSize = [_texture size];
    
    CGFloat imageWidth  = imageSize.width;
    CGFloat imageHeight = imageSize.height;
    

    // Calculate sheet's dimensions in tiles:
    
    _tilesWide = imageWidth / _tileSize;
    _tilesHigh = imageHeight/ _tileSize;
    
    

    // Allocate one brush pattern per tile. Calculate and store
    // its texture coordinates
    
    NSUInteger tileCount = _tilesWide*_tilesHigh;
    
    _palette = calloc(sizeof(TilesetSwatch), tileCount);
    
    
    for (NSUInteger j = 0; j < _tilesHigh; j++ ) {
        
        for (NSUInteger i = 0; i < _tilesWide ; i++) {
            
            // Linear index:
            NSUInteger index = (j*_tilesWide) + i;
            // (row*width + column)
            
            
            // Range of the pattern, in points:
            
            NSUInteger x0 = ( i )*_tileSize;
            NSUInteger x1 = (i+1)*_tileSize;
            NSUInteger y0 = ( j )*_tileSize;
            NSUInteger y1 = (j+1)*_tileSize;
            
            
            // Range of pattern, in normalized
            //  texture coordinates:
            
            _palette[index].s0 = x0 / imageWidth;
            _palette[index].s1 = x1 / imageWidth;
            _palette[index].t0 = y0 / imageHeight;
            _palette[index].t1 = y1 / imageHeight;
        }
    }
    
    // .....................................................................
    // Store brushes with attributes specified
    
    _namedBrushes = [NSMutableDictionary new];
    
    for (NSDictionary* fileBrush in _brushDictionary) {
        
        NSUInteger index = [[fileBrush objectForKey:@"Index"] unsignedIntegerValue];
        
        NSString* classString = [[fileBrush objectForKey:@"Class"] copy];
        
        if (classString) {
            // Named brush
            
            // Get C string and its length
            NSUInteger  utf8Length = [classString lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
            utf8Length += 1; // Make room for '\0'
            
            const char* utf8String = [classString UTF8String];
            
            // Allocate buffer pointed to by brush struct
            _palette[index].namePtr = malloc(utf8Length * sizeof(char));
            
            
            // Store string in brush struct
            strncpy(_palette[index].namePtr, utf8String, utf8Length);            
        }
    }
}


#pragma mark - Custom Accessors


- (void) setTexture:(DNRTexture *)texture {

    if (texture != _texture) {
        
        [_texture relinquish];
        
        _texture = texture;
        
        [_texture aquire];
        
        [self destroyPalette];
        [self createPalette];
    }
}


- (NSString *)name {

    return _imageName;
}


- (NSString *)imageFilePath {

    if (_imageDirectoryPath == nil) {
        
        // [ A ] Bundled resource
        
        return [[NSBundle mainBundle] pathForResource:_imageName ofType:@"png"];
    }
    else{
        // [ B ] Downloaded resource
        
        // TODO: implement
        // Decide location of root directory for saved maps.
        return nil;
    }
}


- (NSString *)mapObjectIdentifierForBrushIndex:(NSUInteger) brushIndex {

    /* 
     Map layers only store the brush index of named tiles, not the actual
     string (to avoid duplication and reduce stored size). On initialization, 
     layers query the identifier and in turn ask the data source for map objects 
     by name.
     */
    
    if (brushIndex < (_tilesWide*_tilesHigh)) {
        
        TilesetSwatch info = _palette[brushIndex];
        
        if (info.namePtr) {
            return [NSString stringWithUTF8String:(info.namePtr)];
        }
    }
    
    return nil;
}


- (NSUInteger) paletteSize {

    return (_tilesWide*_tilesHigh);
}

@end
