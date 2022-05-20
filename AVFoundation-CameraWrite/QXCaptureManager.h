//
//  QXCaptureManager.h
//  AVFoundation-CameraWrite
//
//  Created by 秦菥 on 2022/5/19.
//

#import <AVFoundation/AVFoundation.h>
#import "QXImageTarget.h"
NS_ASSUME_NONNULL_BEGIN

@interface QXCaptureManager : NSObject

@property (nonatomic, strong, readonly) AVCaptureSession *captureSession;
@property (nonatomic, strong, readonly) dispatch_queue_t dispatchQueue;

@property (weak, nonatomic) id <QXImageTarget> imageTarget;

- (BOOL)setupSession:(NSError **)error;
- (BOOL)setupSessionInputs:(NSError **)error;
- (BOOL)setupSessionOutputs:(NSError **)error;

- (void)startSession;
- (void)stopSession;

- (void)startRecording;
- (void)stopRecording;
@property (nonatomic, getter = isRecording) BOOL recording;

@end

NS_ASSUME_NONNULL_END
