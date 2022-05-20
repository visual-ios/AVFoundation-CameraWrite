//
//  QXMovieWriter.m
//  AVFoundation-CameraWrite
//
//  Created by 秦菥 on 2022/5/20.
//

#import "QXMovieWriter.h"
#import <CoreImage/CoreImage.h>
#import "QXContextManager.h"
#import "QXPhotoFilters.h"
#import "QXNotifications.h"
#import <UIKit/UIKit.h>
static NSString *const QXVideoFilename = @"movie.mov";

@interface QXMovieWriter()
@property (nonatomic, strong) AVAssetWriter *assetWriter;
@property (nonatomic, strong) AVAssetWriterInput *assetWriteVideoInput;
@property (nonatomic, strong) AVAssetWriterInput *assetWriterAudioInput;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *assetWriteInputPixelBufferAdaptor;;

@property (nonatomic, strong) dispatch_queue_t dispatchQueue;

@property (nonatomic, weak) CIContext *ciContext;
@property (nonatomic) CGColorSpaceRef colorSpace;
@property (nonatomic, strong) CIFilter *activeFilter;

@property (nonatomic, strong) NSDictionary *videoSettings;
@property (nonatomic, strong) NSDictionary *audioSettings;

@property (nonatomic) BOOL firstSample;
@end

@implementation QXMovieWriter

- (instancetype)initWithVideoSettings:(NSDictionary *)videoSettings audioSettings:(NSDictionary *)audioSettings dispatchQueue:(dispatch_queue_t)dispatchQueue
{
    self = [super init];
    if (self) {
        _videoSettings = videoSettings;
        _audioSettings = audioSettings;
        _dispatchQueue = dispatchQueue;
        
        _ciContext = [QXContextManager shareInstance].ciContext;
        _colorSpace = CGColorSpaceCreateDeviceRGB();
        
        _activeFilter = [QXPhotoFilters defaultFilter];
        _firstSample = YES;
        
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];    // 4
        [nc addObserver:self
               selector:@selector(filterChanged:)
                   name:QXFilterSelectionChangedNotification
                 object:nil];
    }
    return self;
}

- (void)dealloc
{
    CGColorSpaceRelease(_colorSpace);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)filterChanged:(NSNotification *)notification {
    self.activeFilter = [notification.object copy];
}

CGAffineTransform QXTransformForDeviceOrientation(UIDeviceOrientation orientation) {
    CGAffineTransform result;

    switch (orientation) {

        case UIDeviceOrientationLandscapeRight:
            result = CGAffineTransformMakeRotation(M_PI);
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            result = CGAffineTransformMakeRotation((M_PI_2 * 3));
            break;

        case UIDeviceOrientationPortrait:
        case UIDeviceOrientationFaceUp:
        case UIDeviceOrientationFaceDown:
            result = CGAffineTransformMakeRotation(M_PI_2);
            break;

        default: // Default orientation of landscape left
            result = CGAffineTransformIdentity;
            break;
    }

    return result;
}


- (void)startWriting
{
    dispatch_async(self.dispatchQueue, ^{
        
        NSError *error = nil;
        
        NSString *fileType = AVFileTypeQuickTimeMovie;
        
        self.assetWriter = [AVAssetWriter assetWriterWithURL:[self outputURL] fileType:fileType error:&error];
        
        if (!self.assetWriter || error) {
            NSLog(@"error create AVAssetWriter");
            return;
        }
        
        self.assetWriteVideoInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:self.videoSettings];
        
        self.assetWriteVideoInput.expectsMediaDataInRealTime = YES;
        
        UIDeviceOrientation orientation = UIDeviceOrientationPortrait;
        self.assetWriteVideoInput.transform =                              // 4
            QXTransformForDeviceOrientation(orientation);
        
        NSDictionary *attributes = @{
            (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA),
            (id)kCVPixelBufferWidthKey : self.videoSettings[AVVideoWidthKey],
            (id)kCVPixelBufferHeightKey : self.videoSettings[AVVideoHeightKey],
            (id)kCVPixelFormatOpenGLESCompatibility : (id)kCFBooleanTrue
        };
        
        self.assetWriteInputPixelBufferAdaptor = [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:self.assetWriteVideoInput sourcePixelBufferAttributes:attributes];
        
        if ([self.assetWriter canAddInput:self.assetWriteVideoInput]) {
            [self.assetWriter addInput:self.assetWriteVideoInput];
        } else {
            NSLog(@"error add video input");
            return;
        }
        
        self.assetWriterAudioInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:self.audioSettings];
        self.assetWriterAudioInput.expectsMediaDataInRealTime = YES;
        if ([self.assetWriter canAddInput:self.assetWriterAudioInput]) {
            [self.assetWriter addInput:self.assetWriterAudioInput];
        } else {
            NSLog(@"error add audio input");
        }
        
        self.isWriting = YES;
        self.firstSample = YES;
        
    });
}

- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    if (!self.isWriting) {
        return;
    }
    
    CMFormatDescriptionRef formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer);
    
    CMMediaType mediaType = CMFormatDescriptionGetMediaType(formatDesc);
    
    if (mediaType == kCMMediaType_Video) {
        
        CMTime timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        
        if (self.firstSample) {
            if ([self.assetWriter startWriting]) {
                [self.assetWriter startSessionAtSourceTime:timestamp];
            } else {
                NSLog(@"Failed to start writing");
            }
            self.firstSample = NO;
        }
        
        CVPixelBufferRef outputRenderBuffer = NULL;
        
        CVPixelBufferPoolRef pixelBufferPool = self.assetWriteInputPixelBufferAdaptor.pixelBufferPool;
        
        OSStatus err = CVPixelBufferPoolCreatePixelBuffer(NULL, pixelBufferPool, &outputRenderBuffer);
        
        if (err) {
            NSLog(@"unable ti create a pixel buffer from the pool");
            return;
        }
        
        CVPixelBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        
        CIImage *sourceImage = [CIImage imageWithCVPixelBuffer:imageBuffer];
        
        [self.activeFilter setValue:sourceImage forKey:kCIInputImageKey];
        
        CIImage *filteredImage = self.activeFilter.outputImage;
        
        if (!filteredImage) {
            filteredImage = sourceImage;
        }
        
        [self.ciContext render:filteredImage toCVPixelBuffer:outputRenderBuffer bounds:filteredImage.extent colorSpace:self.colorSpace];
        
        if (self.assetWriteVideoInput.readyForMoreMediaData) {             // 6
            if (![self.assetWriteInputPixelBufferAdaptor
                            appendPixelBuffer:outputRenderBuffer
                         withPresentationTime:timestamp]) {
                NSLog(@"Error appending pixel buffer.");
            }
        }
        
        CVPixelBufferRelease(outputRenderBuffer);
    } else if (!self.firstSample && mediaType == kCMMediaType_Audio) {
        if (self.assetWriterAudioInput.isReadyForMoreMediaData) {
            if (![self.assetWriterAudioInput appendSampleBuffer:sampleBuffer]) {
                NSLog(@"Error appending audio sample buffer.");
            }
        }
    }
}

- (void)stopWriting
{
    self.isWriting = NO;
    dispatch_async(self.dispatchQueue, ^{
        [self.assetWriter finishWritingWithCompletionHandler:^{
            if (self.assetWriter.status == AVAssetWriterStatusCompleted) {
                dispatch_async(dispatch_get_main_queue(), ^{                // 3
                    NSURL *fileURL = [self.assetWriter outputURL];
                    [self.delegate didWriteMovieURL:fileURL];
                });
            } else {
                NSLog(@"Failed to write movie: %@", self.assetWriter.error);
            }
        }];
    });
}

- (NSURL *)outputURL {
    NSString *filePath =
        [NSTemporaryDirectory() stringByAppendingPathComponent:QXVideoFilename];
    NSURL *url = [NSURL fileURLWithPath:filePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
        [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
    }
    return url;
}

@end
