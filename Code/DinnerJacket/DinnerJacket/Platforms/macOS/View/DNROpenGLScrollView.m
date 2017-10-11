//
//  DNROpenGLScrollView.m
//  DinnerJacket
//
//  Created by Nicolás Fernando Miari on 2016/09/15.
//  Copyright © 2016 Nicolás Miari. All rights reserved.
//

#import "DNROpenGLScrollView.h"
#import "DNRRenderer.h"


@interface DNROpenGLScrollView ()

@property (nonatomic, readwrite, weak) IBOutlet NSScrollView* scrollView;

@end


@implementation DNROpenGLScrollView


- (void) commonSetup {
    [super commonSetup];
    _scrollPosition = CGPointZero;
    
    //CGRect frame = self.frame;
}

- (void) scroll:(id) sender {
    
}

- (void) scrollWheel:(NSEvent*) event {
    
    CGFloat deltaX = [event deltaX];
    CGFloat deltaY = [event deltaY];
    
    _scrollPosition.x += deltaX;
    _scrollPosition.y += deltaY;
    
    
    [self.renderer setScrollOffset: _scrollPosition];
    
    // scroll canvas
    // TODO: Implement
    
    // update scrollers
    // TODO: Implement
}


@end
