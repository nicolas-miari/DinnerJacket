//
//  DNRFrameAnimationSequence.m
//  DinnerJacket
//
//  Created by Nicolás Miari on 2015/11/09/.
//  Copyright © 2015 Nicolas Miari. All rights reserved.
//

#import "DNRFrameAnimationSequence.h"

#import "DNRSpriteFrame.h"



@interface DNRFrameAnimationSequence ()

@property (nonatomic, readwrite) NSMutableDictionary* framesBySubimageName;

@end


@implementation DNRFrameAnimationSequence


+ (instancetype) animationSequenceNamed:(NSString *) name {

    NSString* path = [[NSBundle mainBundle] pathForResource:name ofType:@"plist"];
    
    return [[self alloc] initWithContentsOfFile:path];
}


- (instancetype) initWithContentsOfFile:(NSString *) path {

    NSDictionary* dictionary = [[NSDictionary alloc] initWithContentsOfFile:path];
    
    return [self initWithDictionary:dictionary];
}


- (instancetype) initWithDictionary:(NSDictionary *)dictionary {
    
    if (self = [super init]) {
        
        NSNumber* count = [dictionary objectForKey:@"RepeatCount"];
        
        if (count){
            _repeatCount = [count integerValue];
        }
        else{
            _repeatCount = 1;
        }
        
        _framesBySubimageName = [NSMutableDictionary new];
        
        _atlasName = [[dictionary objectForKey:@"AtlasName"] copy];
        
        NSMutableArray* frames = [NSMutableArray new];
        
        NSArray *frameDictionaries = [dictionary objectForKey:@"Frames"];
        
        for (NSDictionary* frameDictionary in frameDictionaries) {
            
            NSString* subimageName  = [frameDictionary objectForKey:@"SubimageName"];
            CFTimeInterval duration = [[frameDictionary objectForKey:@"Duration"] floatValue];
            
            DNRSpriteFrame* frame = [[DNRSpriteFrame alloc] initWithSubimageName:subimageName
                                                                        duration:duration];
            [frames addObject:frame];
            
            [_framesBySubimageName setObject:frame forKey:subimageName];
        }
        
        _frames = [frames copy];
    }
    
    return self;
}


- (NSArray*) subimageNames {
    
    return [_framesBySubimageName allKeys];
}
@end
