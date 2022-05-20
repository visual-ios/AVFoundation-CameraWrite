//
//  ViewController.m
//  AVFoundation-CameraWrite
//
//  Created by 秦菥 on 2022/5/19.
//

#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

#import "ViewController.h"
#import "QXCaptureManager.h"
#import "QXPreviewView.h"
#import "QXCaptureButton.h"
#import "QXContextManager.h"
#import "QXPhotoFilters.h"
#import "QXNotifications.h"
@interface ViewController ()
@property (nonatomic, strong) QXCaptureManager *captureManager;
@property (nonatomic, strong) QXPreviewView *previewView;
@property (nonatomic, strong) QXCaptureButton *captureBtn;
@property (nonatomic, copy) NSArray *filterNames;
@property (nonatomic, assign) NSInteger currentFilterIndex;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
    
    self.filterNames = [QXPhotoFilters filterDisplayNames];
    self.currentFilterIndex = 0;
    
    self.captureManager = [[QXCaptureManager alloc] init];
    CGRect frame = self.view.bounds;
    EAGLContext *eaglContext = [QXContextManager shareInstance].eaglContext;
    
    self.previewView = [[QXPreviewView alloc] initWithFrame:frame context:eaglContext];
    self.previewView.filter = [QXPhotoFilters defaultFilter];
    self.captureManager.imageTarget = self.previewView;
    
    self.previewView.coreImageContext = [QXContextManager shareInstance].ciContext;
    [self.view addSubview:self.previewView];
    
    NSError *error;
    if ([self.captureManager setupSession:&error]) {
        [self.captureManager startSession];
    } else {
        
    }
    
    self.captureBtn = [QXCaptureButton captureButton];
    self.captureBtn.center = CGPointMake(kScreenWidth  / 2, kScreenHeight - 100);
    [self.captureBtn addTarget:self action:@selector(didRecord:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.captureBtn];
    
    UIButton *filterBtn = [[UIButton alloc] initWithFrame:CGRectMake(kScreenWidth - 80, 60, 80, 40)];
    [filterBtn setTitle:@"切换滤镜" forState:UIControlStateNormal];
    [filterBtn addTarget:self action:@selector(didChangeFilter) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:filterBtn];
}


- (void)didRecord:(UIButton *)sender
{
    if (!self.captureManager.isRecording) {
        dispatch_async(dispatch_queue_create("com.tapharmonic.kamera", NULL), ^{
            [self.captureManager startRecording];
        });
    } else {
        [self.captureManager stopRecording];
    }
    sender.selected = !sender.selected;
}

- (void)didChangeFilter
{
    if (++self.currentFilterIndex == self.filterNames.count) {
        self.currentFilterIndex = 0;
    }
    NSString *filterName = self.filterNames[self.currentFilterIndex];
    CIFilter *filter = [QXPhotoFilters filterForDisplayName:filterName];
    [[NSNotificationCenter defaultCenter] postNotificationName:QXFilterSelectionChangedNotification object:filter];
}
@end
