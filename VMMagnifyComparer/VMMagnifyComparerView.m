//
//  VMMagnifyComparerView.m
//  VMMagnifyComparerExample
//
//  Created by Sun Peng on 14-7-14.
//  Copyright (c) 2014年 Void Main. All rights reserved.
//

#import "VMMagnifyComparerView.h"

#define kDefaultMagnification       2
#define kDefaultMagnifierSizeRatio  3
#define kOffScreenX                 -100000
#define kOffScreenY                 -100000

@interface VMMagnifyComparerView (ImageSize)

- (CGSize)imageScale;
- (CGRect)imageRect;

@end

@implementation VMMagnifyComparerView

@synthesize magnification = _magnification;
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

- (void)viewDidEndLiveResize
{
    [self resetTrackingRect];

    // Force re-calculate magifier size
    self.magnifierSizeRatio = self.magnifierSizeRatio;
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

    NSRect imageRect = NSRectFromCGRect([self imageRect]);
    float shorterSide = MIN(imageRect.size.width, imageRect.size.height);
    [_magnifier setFrameSize:NSMakeSize(shorterSide / self.magnifierSizeRatio,
                                        shorterSide / self.magnifierSizeRatio)];

    float widthRatio = fmaxf(self.image.size.width / self.frame.size.width, 1);
    float heightRatio = fmaxf(self.image.size.height / self.frame.size.height, 1);
    _imageViewRatio = fmax(widthRatio, heightRatio);
    _minMagnification = fmax(1 / _imageViewRatio, 1);
    _maxMagnification = 2 * _imageViewRatio;

    // Default to middle point
    self.magnification = (_minMagnification + _maxMagnification) * 0.5;

    [self didChangeValueForKey:@"magnifierSizeRatio"];
}

- (void)setImage:(NSImage *)newImage
{
    [super setImage:newImage];

    // Force re-calculate magifier size
    self.magnifierSizeRatio = self.magnifierSizeRatio;
}

#pragma mark -
#pragma mark Modify Magnification
- (float)magnification
{
    return _magnification;
}

- (void)setMagnification:(float)magnification
{
    [self willChangeValueForKey:@"magnification"];

    if (magnification < _minMagnification) magnification = _minMagnification;
    if (magnification > _maxMagnification) magnification = _maxMagnification;

    _magnification = magnification;

    NSPoint screenPoint = [NSEvent mouseLocation];
    NSPoint windowPoint = [self.window convertScreenToBase:screenPoint];
    [self showMagnifierAtLocation:windowPoint];

    [self didChangeValueForKey:@"magnification"];
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
    [self showMagnifierAtLocation:center];
}

- (void)showMagnifierAtLocation:(NSPoint)center
{
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

        float imageBlockWidth = _magnifier.frame.size.width / self.magnification;
        float imageBlockHeight = _magnifier.frame.size.height / self.magnification;

        float relativeOriX = center.x - imageRect.origin.x - imageBlockWidth * 0.5;
        float relativeOriY = center.y - imageRect.origin.y - imageBlockHeight * 0.5;
        NSRect relativeRect = NSMakeRect(relativeOriX,
                                         relativeOriY,
                                         imageBlockWidth * 0.5,
                                         imageBlockHeight);

        relativeRect = [self constrainRect:relativeRect
                                    within:NSMakeRect(0, 0, imageRect.size.width, imageRect.size.height)];

        NSRect normRect = NSMakeRect(relativeRect.origin.x    / imageRect.size.width,
                                     relativeRect.origin.y    / imageRect.size.height,
                                     relativeRect.size.width  / imageRect.size.width,
                                     relativeRect.size.height / imageRect.size.height);

        float imageWidth = self.image.size.width;
        float imageHeight = self.image.size.height;
        NSRect roiRect = NSMakeRect(normRect.origin.x * imageWidth,
                                    normRect.origin.y * imageHeight,
                                    normRect.size.width * imageWidth,
                                    normRect.size.height * imageHeight);
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

- (void)scrollWheel:(NSEvent *)theEvent
{
    // Scroll up to increase
    // Scroll down to decrease
    self.magnification -= theEvent.deltaY * 0.01;
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
    [self.duelImage drawInRect:NSMakeRect(0, 0, image.size.width * 0.5, image.size.height) fromRect:roi operation:NSCompositeSourceOver fraction:1.0];
    [self.image drawInRect:NSMakeRect(image.size.width * 0.5, 0, image.size.width * 0.5, image.size.height) fromRect:roi operation:NSCompositeSourceOver fraction:1.0];
    [self.segImage drawInRect:NSMakeRect(0, 0, image.size.width, image.size.height) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];

    [image unlockFocus];

    return image;
}


#pragma mark -
#pragma mark Actual Image Size
- (CGSize)imageScale
{
    CGFloat sx = self.frame.size.width / self.image.size.width;
    CGFloat sy = self.frame.size.height / self.image.size.height;
    CGFloat s = 1.0;
    switch (self.imageScaling) {
        case NSImageScaleProportionallyDown:
            s = fminf(fminf(sx, sy), 1);
            return CGSizeMake(s, s);
            break;

        case NSImageScaleProportionallyUpOrDown:
            s = fminf(sx, sy);
            return CGSizeMake(s, s);
            break;

        case NSImageScaleAxesIndependently:
            return CGSizeMake(sx, sy);

        default:
            return CGSizeMake(s, s);
    }
}

CGRect CGRectCenteredInCGRect(CGRect inner, CGRect outer)
{
    return CGRectMake((outer.size.width - inner.size.width) / 2.0, (outer.size.height - inner.size.height) / 2.0, inner.size.width, inner.size.height);
}

CGSize CGSizeScale(CGSize size, float scaleWidth, float scaleHeight)
{
    return CGSizeMake(size.width * scaleWidth, size.height * scaleHeight);
}

CGRect CGRectFromCGSize(CGSize size)
{
    return CGRectMake(0, 0, size.width, size.height);
}

- (CGRect)imageRect
{
    CGSize imgScale = [self imageScale];
    return CGRectCenteredInCGRect(CGRectFromCGSize(CGSizeScale(self.image.size, imgScale.width, imgScale.height)), self.frame);
}

@end
