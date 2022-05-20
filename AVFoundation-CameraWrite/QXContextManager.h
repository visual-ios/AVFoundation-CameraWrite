//
//  QXContextManager.h
//  AVFoundation-CameraWrite
//
//  Created by 秦菥 on 2022/5/20.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface QXContextManager : NSObject
+ (instancetype)shareInstance;

@property (nonatomic, strong, readonly) EAGLContext *eaglContext;

@property (nonatomic, strong, readonly) CIContext *ciContext;

@end

NS_ASSUME_NONNULL_END
