//
//  QXCaptureButton.h
//  AVFoundation-CameraWrite
//
//  Created by 秦菥 on 2022/5/20.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, QXCaptureButtonMode) {
    QXCaptureButtonModePhoto = 0, // default
    QXCaptureButtonModeVideo = 1
};

@interface QXCaptureButton : UIButton
+ (instancetype)captureButton;
+ (instancetype)captureButtonWithMode:(QXCaptureButtonMode)captureButtonMode;

@property (nonatomic) QXCaptureButtonMode captureButtonMode;

@end

NS_ASSUME_NONNULL_END
