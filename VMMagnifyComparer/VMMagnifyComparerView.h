//
//  VMMagnifyComparerView.h
//  VMMagnifyComparerExample
//
//  Created by Sun Peng on 14-7-14.
//  Copyright (c) 2014年 Void Main. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface VMMagnifyComparerView : NSImageView {
    NSImageView *_magnifier;

    BOOL _cursorIsHidden;
    NSTrackingArea *_trackingArea;
}

@property (nonatomic, strong) NSImage *duelImage;
@property (nonatomic, strong) NSImage *segImage;
@property                     float    magnifierSizeRatio;

@end
