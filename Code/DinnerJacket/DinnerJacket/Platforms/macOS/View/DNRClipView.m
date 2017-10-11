//
//  DNRClipView.m
//  DinnerJacket
//
//  Created by Nicolás Fernando Miari on 2017/03/12.
//  Copyright © 2017 Nicolás Miari. All rights reserved.
//

#import "DNRClipView.h"

@implementation DNRClipView

- (NSRect)constrainBoundsRect:(NSRect)proposedClipViewBoundsRect {

    NSRect rect = [super constrainBoundsRect:proposedClipViewBoundsRect];
    NSView * view = self.documentView;

    if (view) {
        if (rect.size.width > view.frame.size.width) {
            rect.origin.x = (view.frame.size.width - rect.size.width) / 2.;
        }
        if(rect.size.height > view.frame.size.height) {
            rect.origin.y = (view.frame.size.height - rect.size.height) / 2.;
        }
    }
    
    return rect;
}

@end
