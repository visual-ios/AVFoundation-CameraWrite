//
//  QXContextManager.m
//  AVFoundation-CameraWrite
//
//  Created by 秦菥 on 2022/5/20.
//

#import "QXContextManager.h"
#import <CoreImage/CoreImage.h>

@implementation QXContextManager

+ (instancetype)shareInstance {
    static dispatch_once_t predicate;
    static QXContextManager *instance = nil;
    dispatch_once(&predicate, ^{instance = [[self alloc] init];});
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        NSDictionary *options = @{kCIContextWorkingColorSpace : [NSNull null]};
        _ciContext = [CIContext contextWithEAGLContext:_eaglContext options:options];
    }
    return self;
}


@end
