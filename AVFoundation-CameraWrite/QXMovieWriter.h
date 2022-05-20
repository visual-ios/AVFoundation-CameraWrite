//
//  QXMovieWriter.h
//  AVFoundation-CameraWrite
//
//  Created by 秦菥 on 2022/5/20.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class QXMovieWriter;

@protocol QXMovieWriterDelegate <NSObject>
- (void)didWriteMovieURL:(NSURL *)outputURL;
@end


@interface QXMovieWriter : NSObject

@property (nonatomic, weak) id<QXMovieWriterDelegate>delegate;

- (instancetype)initWithVideoSettings:(NSDictionary *)videoSettings audioSettings:(NSDictionary *)audioSettings dispatchQueue:(dispatch_queue_t)dispatchQueue;

- (void)startWriting;
- (void)stopWriting;
@property (nonatomic, assign) BOOL isWriting;

- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@end

NS_ASSUME_NONNULL_END
