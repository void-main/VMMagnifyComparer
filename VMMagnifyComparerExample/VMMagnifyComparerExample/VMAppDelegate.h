//
//  VMAppDelegate.h
//  VMMagnifyComparerExample
//
//  Created by Sun Peng on 14-7-14.
//  Copyright (c) 2014年 Void Main. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class VMMagnifyComparerView;
@interface VMAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet VMMagnifyComparerView *magnifyComparerView;

@end
