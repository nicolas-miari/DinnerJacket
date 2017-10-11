//
//  DNRTexture.m
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-05-03.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import "DNRBase.h"

#import "DNRTexture.h"


#import "DNRGLCache.h"

#ifdef DNRPlatformPhone
#import "../../../iOS/ViewController/DNRViewController.h"
#else
#import "../../../macOS/ViewController/DNRViewController.h"
#endif


#import "DNRGlobals.h"

#import "DNRSceneController.h"


// .............................................................................
//

static NSMutableDictionary* texturesByName = nil;



// Exported constants

NSString* const kDNRTextureOptionsShareGroupKey = @"ShareGroup";
NSString* const kDNRTextureOptionsFilterKey     = @"Filter";


// Internal constants

NSString* const kHiResFileNameSuffix  = @"@2x";


// Helper C functions

BOOL IsPowerOfTwo(int x) {
    
    while( ((x % 2) == 0) && (x > 1) ){ // While x is even grater than one
        x /= 2;
    }
    
    // Only a power of two can be divided evenly by two all the way down to 1:
    return (x == 1);
}


NSString* setNativeResolutionSuffix(NSString* fileName){
    
    unsigned long scale = floorf(screenScaleFactor);

    NSString* pathExtension = [fileName pathExtension];
    NSString* stripped = [fileName stringByDeletingPathExtension];
    
    NSArray* components = [stripped componentsSeparatedByString:@"@"];
    
    NSString* suffix = [NSString stringWithFormat:@"@%lux", scale];
    
    NSString* qualified = [components[0] stringByAppendingString:suffix];
    
    if (pathExtension != nil){
        qualified = [qualified stringByAppendingPathExtension:pathExtension];
    }
    
    return qualified;
}


/**
 Scans the directory containing the file specified by `originalImagePath` for 
 an image file name with the same name but a suffix that best matches the 
 device's native screen resolution.
 Examples:
 
 - If you pass "/image.png" on a retina Mac, and the directory contains
 the file "/image@2x.png", that is returned. 
 
 - If you pass "/image.png" on an iPhone 7 Plus, and the directory contains
 the file "/image@3x.png", that is returned. Otherwise, the function searches 
 for "/image@2x.png", and if that fials, it settles for the original path.
 */
NSString* imagePathWithBestResolutionAvailable(NSString* originalImagePath){

    unsigned int scale = floorf(screenScaleFactor);
    
    NSString* fileName  = [originalImagePath lastPathComponent];
    NSString* directory = [originalImagePath stringByDeletingLastPathComponent];
    
    NSString* pathExtension = [fileName pathExtension];
    if (pathExtension == nil){
        pathExtension = @"";
    }
    NSString* strippedName  = [fileName stringByDeletingPathExtension];
    
    NSArray* components = [strippedName componentsSeparatedByString:@"@"];
    NSString* baseName  = [components objectAtIndex:0];
    
    NSFileManager* fileManager = [NSFileManager defaultManager];
    
    while (scale > 0) {
        NSString* suffix = scale > 1 ? [NSString stringWithFormat:@"@%ux", scale] : @"";
        NSString* qualified = [baseName stringByAppendingString:suffix];
        NSString* extended  = [qualified stringByAppendingPathExtension:pathExtension];
        NSString* path      = [directory stringByAppendingPathComponent:extended];
        
        if ([fileManager fileExistsAtPath:path]){
            return path;
        }
        scale--;
    }
    
    return nil;
}


CGFloat scaleFactorOfImageFileName(NSString* fileName){
    NSArray* components = [fileName componentsSeparatedByString:@"@"];
    
    if ([components count] > 1) {
        NSString* secondComponent = components[1];
        return [secondComponent floatValue];
    }
    
    return  1.0;
}

// .............................................................................


@interface DNRTexture ()

/// Device scale factor.
@property (nonatomic, readwrite) CGFloat     scaleFactor;

/// Native width (in pixels).
@property (nonatomic, readwrite) GLuint      pixelWidth;

/// Native height (in pixels).
@property (nonatomic, readwrite) GLuint      pixelHeight;

@end


// .............................................................................

@implementation DNRTexture

#pragma mark - Factory / Instance Management


+ (void) initialize {
    
    if (self == [DNRTexture class]) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            texturesByName = [NSMutableDictionary new];
        });
    }
}


+ (DNRTexture*) textureWithContentsOfFile:(NSString *)path
                                  options:(NSDictionary *)options {
    
    DNRTexture* texture = [texturesByName objectForKey:path];
    
    if (!texture) {
        // Cache miss; Create:
        texture = [[DNRTexture alloc] initWithContentsOfFile:path
                                                     options:options];
        
        // Cache for next time:
        if (texture != nil) {
            [texturesByName setObject:texture forKey:path];
        }
    }
    
    return texture;
}


+ (void) loadTextureWithContentsOfFile:(NSString *)path
                               options:(NSDictionary *)options
                            completion:(DNRResourceLoadingCompletionHandler) completionHandler {
    
    DNRTexture* texture = [texturesByName objectForKey:path];
    
    if (texture) {
        // [ A ] CACHE HIT: Return it right away on the main thread.
        
        if ([NSThread isMainThread]) {
            completionHandler(@[texture]);
        }
        else{
            dispatch_async( dispatch_get_main_queue(), ^{
                completionHandler(@[texture]);
            });
        }
    }
    else{
        // [ B ] CACHE MISS: Create it, cache it, return in on the main thread.
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(){
            // (BACKGROUND THREAD)
            
            DNRTexture* texture = [[DNRTexture alloc] initWithContentsOfFile:path options:options];

            if (texture) {
               [texturesByName setObject:texture forKey:path];
            }
            
            dispatch_async( dispatch_get_main_queue(), ^{
                // (MAIN THREAD)
                completionHandler(texture ? @[texture] : nil);
            });
        });
    }
}


+ (void) purgeUnusedTextures {
    
    NSMutableArray* keysToDelete = [NSMutableArray new];
    
    for (NSString* key in [texturesByName allKeys]) {
        
        DNRTexture* texture = [texturesByName objectForKey:key];
        
        if ([texture useCount] < 1) {
            [keysToDelete addObject:key];
        }
    }
    
    [texturesByName removeObjectsForKeys:keysToDelete];
}


#pragma mark - Initialization

- (instancetype) initWithContentsOfFile:(NSString *)path
                                options:(NSDictionary *)options {
    
    if ((self = [super init])) {
        
        _useCount = 0;
        
        
        NSString* optimalPath = imagePathWithBestResolutionAvailable(path);
        
        NSString* fileName = [optimalPath lastPathComponent];
        
        _scaleFactor = scaleFactorOfImageFileName(fileName);
        
        // TODO: Rethink hi-res-from-file-name logic.
        
#ifdef DNRPlatformPhone
        // iOS
        UIImage* image = [[UIImage alloc] initWithContentsOfFile:optimalPath];
        
        CGImageRef imageRef = [image CGImage];
        
        if (imageRef == NULL){
            return nil;
        }
        
        _pixelWidth  = (GLuint) CGImageGetWidth(imageRef);
        _pixelHeight = (GLuint) CGImageGetHeight(imageRef);
        
#else
        // macOS
        NSArray* imageRepresentations = [NSBitmapImageRep imageRepsWithContentsOfFile:optimalPath];
        
        GLuint maxWidth  = 0;
        GLuint maxHeight = 0;
        NSBitmapImageRep* largestImageRep;
        
        for (NSImageRep * imageRep in imageRepresentations) {
            if ([imageRep pixelsWide] > maxWidth){
                maxWidth  = (GLuint)[imageRep pixelsWide];
                maxHeight = (GLuint)[imageRep pixelsHigh];
                largestImageRep = (NSBitmapImageRep*) imageRep;
            }
        }
        
        _pixelWidth = maxWidth;
        _pixelHeight = maxHeight;
        
        CGImageRef imageRef = [largestImageRep CGImage];
        
        if (imageRef == NULL){
            return nil;
        }
#endif
        
        BOOL isPOT = (IsPowerOfTwo(_pixelWidth) && IsPowerOfTwo(_pixelHeight));
        BOOL usingBackgroundContext = ([NSThread isMainThread] == NO);

        
        if (usingBackgroundContext) {
            
#ifdef DNRPlatformPhone     // iOS (OpenGL ES)
            EAGLContext* backgroundContext = [[DNRViewController sharedController] backgroundRenderingContext];
            [EAGLContext setCurrentContext:backgroundContext];
#else                       // macOS (OpenGL)
            NSOpenGLContext* backgroundContext = [[DNRViewController sharedController] backgroundRenderingContext];
            [backgroundContext makeCurrentContext];
#endif
        }
        
    
        glGenTextures(1, &_name);
        
        if (usingBackgroundContext) {
            glBindTexture(GL_TEXTURE_2D, _name);
        }
        else{
            bindTexture2D(_name);
        }
        
        
        // .. ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ..
        // Configure texture object
        
        // 1. Start by defaulting to nearest filter (sprite)
        unsigned int filter = GL_NEAREST;
        
        // 2. Get option, if available
        NSNumber* filterOption = [options objectForKey:kDNRTextureOptionsFilterKey];
        if (filterOption) {
            filter = [filterOption unsignedIntValue];
        }
        
        // 3. Set the specified filtering:
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, filter);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, filter);
        
        
        if (filter == GL_LINEAR && !isPOT) {
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        }
        
        
        // .. ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ..
        // Transfer source image data to texture buffer
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        
        void* imageData = malloc(_pixelWidth*_pixelHeight*4); // 4 bytes per pixel
        
        CGContextRef context = CGBitmapContextCreate(imageData,         // Buffer
                                                     _pixelWidth,       // Width
                                                     _pixelHeight,      // Height
                                                     8,                 // Bits per component
                                                     4* _pixelWidth,    // Bytes per row
                                                     colorSpace,        // Color space
                                                     kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
        CGColorSpaceRelease(colorSpace);
        

        CGContextSetBlendMode(context, kCGBlendModeCopy);// TEST
        
        CGContextClearRect( context, CGRectMake(0, 0, _pixelWidth, _pixelHeight));
        
//        if(1){// TEST
//            CGContextTranslateCTM(context, 0.0, _pixelHeight);
//            CGContextScaleCTM(context, 1.0, -1.0);
//        }
        
        CGContextDrawImage( context, CGRectMake(0, 0, _pixelWidth, _pixelHeight), imageRef);
        
        glTexImage2D(GL_TEXTURE_2D,
                     0,
                     GL_RGBA,
                     _pixelWidth,
                     _pixelHeight,
                     0,
                     GL_RGBA,
                     GL_UNSIGNED_BYTE,
                     imageData);
        
        if (usingBackgroundContext) {
            glBindTexture(GL_TEXTURE_2D, 0);
            glFlush();
        }
        else{
            // TODO: use cache
            bindTexture2D(0);
        }
        
        CGContextRelease(context);
        free(imageData);
    }
    
    return self;
}


- (void) dealloc {
    glDeleteTextures(1, &_name);
}


#pragma mark - Custom Accessors


- (CGSize) size {
    return CGSizeMake(_pixelWidth/_scaleFactor, _pixelHeight/_scaleFactor);
}


#pragma mark - Operation


- (void) aquire {
    _useCount++;
}


- (void) relinquish {
    _useCount--;
}


@end
