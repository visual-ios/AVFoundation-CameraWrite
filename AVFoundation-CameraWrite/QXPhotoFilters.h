//
//  QXPhotoFilters.h
//  AVFoundation-CameraWrite
//
//  Created by 秦菥 on 2022/5/20.
//

#import <Foundation/Foundation.h>
#import <CoreImage/CoreImage.h>
NS_ASSUME_NONNULL_BEGIN

@interface QXPhotoFilters : NSObject

+ (NSArray *)filterNames;
+ (NSArray *)filterDisplayNames;
+ (CIFilter *)filterForDisplayName:(NSString *)displayName;
+ (CIFilter *)defaultFilter;

@end

NS_ASSUME_NONNULL_END
