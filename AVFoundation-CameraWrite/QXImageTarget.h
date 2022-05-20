//
//  QXImageTarget.h
//  AVFoundation-CameraWrite
//
//  Created by 秦菥 on 2022/5/20.
//

#import <CoreImage/CoreImage.h>

@protocol QXImageTarget <NSObject>

- (void)setImage:(CIImage *)image;

@end
