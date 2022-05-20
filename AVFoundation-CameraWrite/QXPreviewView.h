//
//  QXPreviewView.h
//  AVFoundation-CameraWrite
//
//  Created by 秦菥 on 2022/5/20.
//

#import <GLKit/GLKit.h>
#import "QXImageTarget.h"

NS_ASSUME_NONNULL_BEGIN

@interface QXPreviewView : GLKView <QXImageTarget>

@property (nonatomic, strong) CIFilter *filter;
@property (nonatomic, strong) CIContext *coreImageContext;

@end

NS_ASSUME_NONNULL_END
