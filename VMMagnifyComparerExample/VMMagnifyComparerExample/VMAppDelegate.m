//
//  VMAppDelegate.m
//  VMMagnifyComparerExample
//
//  Created by Sun Peng on 14-7-14.
//  Copyright (c) 2014年 Void Main. All rights reserved.
//

#import "VMAppDelegate.h"
#import "VMMagnifyComparerView.h"

@implementation VMAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Base image
    self.magnifyComparerView.image = [NSImage imageNamed:@"image1.png"];

    // Compare image
    self.magnifyComparerView.duelImage = [NSImage imageNamed:@"image2.png"];

    // Better use vector images
    self.magnifyComparerView.segImage = [NSImage imageNamed:@"border.pdf"];

    // smallerSideOf(self.frame) / smallerSizeOf(self.magnifyCompareView.frame)
    self.magnifyComparerView.magnifierSizeRatio = 4;
}

@end
