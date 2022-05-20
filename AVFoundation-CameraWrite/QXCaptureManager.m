//
//  QXCaptureManager.m
//  AVFoundation-CameraWrite
//
//  Created by 秦菥 on 2022/5/19.
//

#import "QXCaptureManager.h"
#import "THAssetsLibrary.h"
#import "QXMovieWriter.h"
#import <CoreImage/CoreImage.h>
#import <AssetsLibrary/AssetsLibrary.h>
@interface QXCaptureManager()<QXMovieWriterDelegate,AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureSession *captureSession;

@property (nonatomic, weak) AVCaptureDeviceInput *activeVideoInput;

@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioDataOutput;

@property (nonatomic, strong) NSURL *outputURL;
@property (nonatomic, strong) THAssetsLibrary *library;

@property (nonatomic, strong) QXMovieWriter *movieWriter;
@end

@implementation QXCaptureManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        _library = [[THAssetsLibrary alloc] init];
        _dispatchQueue = dispatch_queue_create("com.capture.queue", NULL);
    }
    return self;
}

- (BOOL)setupSession:(NSError **)error
{
    self.captureSession = [[AVCaptureSession alloc] init];
    self.captureSession.sessionPreset = AVCaptureSessionPresetHigh;
    if (![self setupSessionInputs:error]) {
        return NO;
    }
    if (![self setupSessionOutputs:error]) {
        return NO;
    }
    return YES;
}

- (BOOL)setupSessionInputs:(NSError *__autoreleasing  _Nullable *)error
{
    // Set up default camera device
    AVCaptureDevice *videoDevice =
        [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];

    AVCaptureDeviceInput *videoInput =
        [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:error];
    if (videoInput) {
        if ([self.captureSession canAddInput:videoInput]) {
            [self.captureSession addInput:videoInput];
            self.activeVideoInput = videoInput;
        } else {
            return NO;
        }
    } else {
        return NO;
    }

    // Setup default microphone
    AVCaptureDevice *audioDevice =
        [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];

    AVCaptureDeviceInput *audioInput =
        [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:error];
    if (audioInput) {
        if ([self.captureSession canAddInput:audioInput]) {
            [self.captureSession addInput:audioInput];
        } else {
            return NO;
        }
    } else {
        return NO;
    }

    return YES;
}

- (BOOL)setupSessionOutputs:(NSError *__autoreleasing  _Nullable *)error
{
    self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    NSDictionary *outputSettings = @{(id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)};
    
    self.videoDataOutput.videoSettings = outputSettings;
    self.videoDataOutput.alwaysDiscardsLateVideoFrames = NO;
    
    [self.videoDataOutput setSampleBufferDelegate:self queue:self.dispatchQueue];
    
    if ([self.captureSession canAddOutput:self.videoDataOutput]) {
        [self.captureSession addOutput:self.videoDataOutput];
    } else {
        return NO;
    }
    
    self.audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];         // 3
    
    [self.audioDataOutput setSampleBufferDelegate:self
                                            queue:self.dispatchQueue];
    
    if ([self.captureSession canAddOutput:self.audioDataOutput]) {
        [self.captureSession addOutput:self.audioDataOutput];
    } else {
        return NO;
    }
    
    NSString *fileType = AVFileTypeQuickTimeMovie;
    
    NSDictionary *videoSettings = [self.videoDataOutput recommendedVideoSettingsForAssetWriterWithOutputFileType:fileType];
    
    NSDictionary *audioSettings = [self.audioDataOutput recommendedAudioSettingsForAssetWriterWithOutputFileType:fileType];
    
    self.movieWriter = [[QXMovieWriter alloc] initWithVideoSettings:videoSettings audioSettings:audioSettings dispatchQueue:self.dispatchQueue];
    self.movieWriter.delegate = self;
    
    return YES;
}

- (void)startSession {
    dispatch_async(self.dispatchQueue, ^{
        if (![self.captureSession isRunning]) {
            [self.captureSession startRunning];
        }
    });
}

- (void)stopSession {
    dispatch_async(self.dispatchQueue, ^{
        if ([self.captureSession isRunning]) {
            [self.captureSession stopRunning];
        }
    });

}

- (void)startRecording
{
    [self.movieWriter startWriting];
    self.recording = YES;
}

- (void)stopRecording
{
    [self.movieWriter stopWriting];
    self.recording = NO;
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    [self.movieWriter processSampleBuffer:sampleBuffer];
    
    if (output == self.videoDataOutput) {
        CVPixelBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        
        CIImage *sourceImage = [CIImage imageWithCVPixelBuffer:imageBuffer];
        
        [self.imageTarget setImage:sourceImage];
    }
}

- (void)didWriteMovieURL:(NSURL *)outputURL
{
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:outputURL]) {
        
        ALAssetsLibraryWriteVideoCompletionBlock completionBlock;
        
        completionBlock = ^(NSURL *assetURL, NSError *error){
            if (error) {
                
            }
        };
        
        [library writeVideoAtPathToSavedPhotosAlbum:outputURL
                                    completionBlock:completionBlock];
    }
}
@end
