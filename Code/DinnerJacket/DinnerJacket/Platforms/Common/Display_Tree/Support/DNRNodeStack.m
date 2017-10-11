//
//  DNRNodeStack.m
//  DinnerJacket
//
//  Created by Nicolás Miari on 2014-03-08.
//  Copyright (c) 2014 Nicolas Miari. All rights reserved.
//

#import "DNRNodeStack.h"



@implementation DNRNodeStack {

    NSMutableArray* _stack; // Backing
}


- (id) init {

    if ((self = [super init])) {
        
        _stack = [[NSMutableArray alloc] init];
    }
    
    return self;
}


- (void) pushNode:(DNRNode *)node {

    if (node) {
        
        [_stack addObject:node];
    }
}


- (DNRNode *)popNode {

    if ([_stack count]) {
        
        DNRNode* node = [_stack lastObject];
        
        [_stack removeLastObject];
        
        return node;
    }
    
    return nil;
}


- (void) empty {

    [_stack removeAllObjects];
}


@end
