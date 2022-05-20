//
//  QXPhotoFilters.m
//  AVFoundation-CameraWrite
//
//  Created by 秦菥 on 2022/5/20.
//

#import "QXPhotoFilters.h"
#import "NSString+THAdditions.h"
@implementation QXPhotoFilters

+ (NSArray *)filterNames {
    
    return @[@"CIPhotoEffectChrome",
             @"CIPhotoEffectFade",
             @"CIPhotoEffectInstant",
             @"CIPhotoEffectMono",
             @"CIPhotoEffectNoir",
             @"CIPhotoEffectProcess",
             @"CIPhotoEffectTonal",
             @"CIPhotoEffectTransfer"];
}

+ (NSArray *)filterDisplayNames {
    
    NSMutableArray *displayNames = [NSMutableArray array];

    for (NSString *filterName in [self filterNames]) {
        [displayNames addObject:[filterName stringByMatchingRegex:@"CIPhotoEffect(.*)" capture:1]];
    }

    return displayNames;
}

+ (CIFilter *)defaultFilter {
    return [CIFilter filterWithName:[[self filterNames] firstObject]];
}

+ (CIFilter *)filterForDisplayName:(NSString *)displayName {
    for (NSString *name in [self filterNames]) {
        if ([name containsString:displayName]) {
            return [CIFilter filterWithName:name];
        }
    }
    return nil;
}



@end
