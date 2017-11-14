//
//  LRLVideoPickerController.h
//  V1_Circle
//
//  Created by 刘瑞龙 on 15/7/27.
//  Copyright (c) 2015年 com.Dmeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LRLVideoPickerController : UIImagePickerController

-(id)initWithSourceType:(UIImagePickerControllerSourceType)sourceType andvideoQuality:(UIImagePickerControllerQualityType)videoQuality;

/**
 *@b选取视频成功后的回调
 */
@property (nonatomic, copy) void (^videoPickerSuccess)(NSString * exportPath, UIImagePickerControllerSourceType sourceType, UIImage * videoImage, float videoDuration);

/**
 *@b选取取消后的回调
 */
@property (nonatomic, copy) void (^videoPickerCancle)(UIImagePickerControllerSourceType sourceType);

@end
