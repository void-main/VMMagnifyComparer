//
//  NSImageView+ImageSize.m
//  VMMagnifyComparerExample
//
//  Created by Sun Peng on 14-7-16.
//  Copyright (c) 2014年 Void Main. All rights reserved.
//

#import "NSImageView+ImageSize.h"

@implementation NSImageView (ImageSize)

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
