//
//  VMMagnifyComparerView.m
//  VMMagnifyComparerExample
//
//  Created by Sun Peng on 14-7-14.
//  Copyright (c) 2014年 Void Main. All rights reserved.
//

#import "VMMagnifyComparerView.h"
#import "NSImageView+ImageSize.h"

#define kDefaultMagnifierSizeRatio  3
#define kOffScreenX                 -100000
#define kOffScreenY                 -100000

@implementation VMMagnifyComparerView

@synthesize magnifierSizeRatio = _magnifierSizeRatio;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _magnifier = [[NSImageView alloc] initWithFrame:NSMakeRect(kOffScreenX, kOffScreenY, 0, 0)];
        self.magnifierSizeRatio = kDefaultMagnifierSizeRatio;
        [self addSubview:_magnifier];
    }
    return self;
}

- (void)viewDidMoveToWindow
{
    [self resetTrackingRect];
}

- (float)magnifierSizeRatio
{
    return _magnifierSizeRatio;
}

- (void)setMagnifierSizeRatio:(float)magnifierSizeRatio
{
    [self willChangeValueForKey:@"magnifierSizeRatio"];

    _magnifierSizeRatio = magnifierSizeRatio;
    _magnifierSizeRatio = MAX(_magnifierSizeRatio, 1);

    float shorterSide = MIN(self.frame.size.width, self.frame.size.height);
    [_magnifier setFrameSize:NSMakeSize(shorterSide / self.magnifierSizeRatio,
                                        shorterSide / self.magnifierSizeRatio)];

    [self didChangeValueForKey:@"magnifierSizeRatio"];
}

#pragma mark -
#pragma mark Tracking Mouse Event
- (void)resetTrackingRect
{
    if (_trackingArea) {
        [self removeTrackingArea:_trackingArea];
        _trackingArea = nil;
    }

    _trackingArea = [[NSTrackingArea alloc] initWithRect:[self visibleRect]
                                                 options:NSTrackingActiveInActiveApp | NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved
                                                   owner:self
                                                userInfo:nil];
    [self addTrackingArea:_trackingArea];
}

- (void)mouseMoved:(NSEvent *)theEvent
{
    // Calculate frame rect with new center
    NSPoint center = [theEvent locationInWindow];
    center = [self convertPoint:center fromView:nil];

    NSRect imageRect = NSRectFromCGRect([self imageRect]);
    if (NSPointInRect(center, imageRect)) {
        // Hide the cursor if not yet hidden
        [self hideCursor];

        NSRect newRect = NSMakeRect(center.x - _magnifier.frame.size.width * 0.5,
                                    center.y - _magnifier.frame.size.height * 0.5,
                                    _magnifier.frame.size.width,
                                    _magnifier.frame.size.height);
        newRect = [self constrainRect:newRect within:imageRect];
        _magnifier.frame = newRect;

        float relativeOriX = center.x - imageRect.origin.x - _magnifier.frame.size.width * 0.5;
        float relativeOriY = center.y - imageRect.origin.y - _magnifier.frame.size.height * 0.5;
        NSRect relativeRect = NSMakeRect(relativeOriX,
                                         relativeOriY,
                                         _magnifier.frame.size.width,
                                         _magnifier.frame.size.height);

        relativeRect = [self constrainRect:relativeRect
                                    within:NSMakeRect(0, 0, imageRect.size.width, imageRect.size.height)];

        NSRect normRect = NSMakeRect(relativeRect.origin.x    / imageRect.size.width,
                                     relativeRect.origin.y    / imageRect.size.height,
                                     relativeRect.size.width  / imageRect.size.width,
                                     relativeRect.size.height / imageRect.size.height);

        float imageWidth = self.image.size.width;
        float imageHeight = self.image.size.height;
        NSRect roiRect = NSMakeRect((normRect.origin.x + normRect.size.width * 0.25) * imageWidth,
                                    (normRect.origin.y + normRect.size.height * 0.25) * imageHeight,
                                    normRect.size.width * 0.25 * imageWidth,
                                    normRect.size.height * 0.5 * imageHeight);
        _magnifier.image = [self magnifiedImage:roiRect];
    } else {
        [self unhideCursor];
        [_magnifier setFrameOrigin:NSMakePoint(kOffScreenX, kOffScreenY)];
    }
}

- (void)mouseExited:(NSEvent *)theEvent
{
    [self unhideCursor];
    [_magnifier setFrameOrigin:NSMakePoint(kOffScreenX, kOffScreenY)];
}

- (void)hideCursor
{
    if (!_cursorIsHidden) {
        [NSCursor hide];
        _cursorIsHidden = YES;
    }
}

- (void)unhideCursor
{
    if (_cursorIsHidden) {
        [NSCursor unhide];
        _cursorIsHidden = NO;
    }
}

- (NSRect)constrainRect:(NSRect)rect within:(NSRect)constraint
{
    float newX = rect.origin.x;
    float newY = rect.origin.y;
    float width = rect.size.width;
    float height = rect.size.height;

    if (newX < constraint.origin.x) newX = constraint.origin.x;
    if (newY < constraint.origin.y) newY = constraint.origin.y;
    if (newX + width > (constraint.origin.x + constraint.size.width))
        newX = (constraint.origin.x + constraint.size.width) - width;
    if (newY + height > (constraint.origin.y + constraint.size.height))
        newY = (constraint.origin.y + constraint.size.height) - height;

    return NSMakeRect(newX, newY, width, height);
}

#pragma mark -
#pragma mark Draw Magnified Image
- (NSImage *)magnifiedImage:(NSRect)roi
{
    NSImage *image = [[NSImage alloc] initWithSize:_magnifier.frame.size];
    [image lockFocus];
    [self.image drawInRect:NSMakeRect(0, 0, image.size.width * 0.5, image.size.height) fromRect:roi operation:NSCompositeSourceOver fraction:1.0];
    [self.duelImage drawInRect:NSMakeRect(image.size.width * 0.5, 0, image.size.width * 0.5, image.size.height) fromRect:roi operation:NSCompositeSourceOver fraction:1.0];
    [self.segImage drawInRect:NSMakeRect(0, 0, image.size.width, image.size.height) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];

    [image unlockFocus];

    return image;
}

@end
