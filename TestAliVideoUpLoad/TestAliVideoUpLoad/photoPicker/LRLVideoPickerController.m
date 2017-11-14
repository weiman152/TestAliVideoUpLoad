//
//  LRLVideoPickerController.m
//  V1_Circle
//
//  Created by 刘瑞龙 on 15/7/27.
//  Copyright (c) 2015年 com.Dmeng. All rights reserved.
//

#import "LRLVideoPickerController.h"

#import <AudioUnit/AudioUnit.h>
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface LRLVideoPickerController ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, strong) NSURL * tempUrl;

@end

@implementation LRLVideoPickerController

-(id)initWithSourceType:(UIImagePickerControllerSourceType)sourceType andvideoQuality:(UIImagePickerControllerQualityType)videoQuality{
    if (self = [super init]) {
        if (sourceType == UIImagePickerControllerSourceTypePhotoLibrary) {
            self.allowsEditing = YES;
            self.delegate = self;
            self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            self.mediaTypes =  [[NSArray alloc] initWithObjects:(NSString *)kUTTypeMovie, nil];
            self.sourceType = sourceType;
        }else if(sourceType == UIImagePickerControllerSourceTypeCamera){
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
                self.allowsEditing = YES;
                self.delegate = self;
                self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
                self.mediaTypes =  [[NSArray alloc] initWithObjects:(NSString *)kUTTypeMovie, nil];
                self.sourceType = UIImagePickerControllerSourceTypeCamera;
                self.videoQuality = UIImagePickerControllerQualityTypeMedium;
                self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
            }else{
                UIAlertView * alert = [[UIAlertView alloc] initWithTitle:nil message:@"摄像头不可用" delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles:nil, nil];
                [alert show];
            }
        }
    }
    return self;
}

-(void)dealloc{
    self.tempUrl = nil;
    self.videoPickerSuccess = nil;
    self.videoPickerCancle = nil;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self voicePlace];
}

#pragma mark - 设置音频
- (void)voicePlace{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryAmbient error:nil];
    [audioSession setActive:YES error:nil];
}

#pragma mark - 从相册或者摄像头选取视频成功后的回调
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    NSURL *videoUrl = [info objectForKey:UIImagePickerControllerMediaURL];
    NSString * videoStrPath = videoUrl.path;
    //从摄像头选取视频, 使用系统所给的剪辑器进行剪辑,不能返回剪辑后的视频,而是返回完成视频,和剪辑开始和结束的时间;
    if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
        if ([info valueForKey:@"_UIImagePickerControllerVideoEditingStart"]) {
            float startTime = [[info valueForKey:@"_UIImagePickerControllerVideoEditingStart"] floatValue];
            float endTime = [[info valueForKey:@"_UIImagePickerControllerVideoEditingEnd"] floatValue];
            [self filmEditingWithStartTime:startTime andEndTime:endTime andVideoUrl:videoUrl andImagePicker:picker];
            return;
        }else{
            _tempUrl = videoUrl;
            UISaveVideoAtPathToSavedPhotosAlbum(videoStrPath, self, @selector(video:didFinishSavingWithError:contextInfo:),nil);
        }
    }else if(picker.sourceType == UIImagePickerControllerSourceTypePhotoLibrary){
        _tempUrl = videoUrl;
    }
    [self writeToCacheAndInitialSaveWithVideoPathStr:videoStrPath andPicker:picker];
}

#pragma mark - 根据返回的开始和结束时间进行视频剪辑
-(void)filmEditingWithStartTime:(float)startTime andEndTime:(float)endTime andVideoUrl:(NSURL *)videoUrl andImagePicker:(UIImagePickerController *)picker{
    NSString * videoStrPath = videoUrl.path;
    AVAsset * asset = [AVAsset assetWithURL:videoUrl];
    AVAssetTrack * assetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    
    AVMutableComposition * composition = [AVMutableComposition composition];
    AVMutableCompositionTrack * track = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    [track insertTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(startTime, 30), CMTimeMakeWithSeconds(endTime - startTime, 30)) ofTrack:assetTrack atTime:kCMTimeZero error:nil];
    
    NSFileManager * manager = [[NSFileManager alloc] init];
    if ([manager fileExistsAtPath:videoStrPath]) {
        if([manager removeItemAtPath:videoStrPath error:nil]){
            NSLog(@"remove success");
        }else{
            NSLog(@"remove failed");
        }
    }
    AVAssetExportSession * exportSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPreset640x480];
    exportSession.outputFileType = AVFileTypeQuickTimeMovie;
    exportSession.outputURL = videoUrl;
    exportSession.shouldOptimizeForNetworkUse = YES;
    __weak LRLVideoPickerController * weakSelf = self;
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        switch (exportSession.status) {
            case AVAssetExportSessionStatusFailed:
                NSLog(@"failed");
                break;
            case AVAssetExportSessionStatusCompleted:
            {
                weakSelf.tempUrl = videoUrl;
                UISaveVideoAtPathToSavedPhotosAlbum(videoStrPath, weakSelf, @selector(video:didFinishSavingWithError:contextInfo:),nil);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self writeToCacheAndInitialSaveWithVideoPathStr:videoStrPath andPicker:picker];
                });
                NSLog(@"completed");
            }
                break;
            default:
                break;
        }
    }];
}

#pragma mark - 将视频写入cache路径并在结束后实例化SaveAndPublishViewController
-(void)writeToCacheAndInitialSaveWithVideoPathStr:(NSString *)videoStrPath andPicker:(UIImagePickerController *)picker{
    AVAsset * asset = [AVAsset assetWithURL:_tempUrl];
    CMTime assetTime = [asset duration];
    float duration = CMTimeGetSeconds(assetTime);
    UIImage * videoImage = [self getImage:videoStrPath];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData * data = [NSData dataWithContentsOfURL:_tempUrl];
        NSString * cacheStr = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        NSDate * date = [NSDate date];
        NSDateFormatter * dateFormater = [[NSDateFormatter alloc] init];
        dateFormater.dateFormat = @"yyyy-MM-ddHH:mm:ss";
        NSString * currentTime = [dateFormater stringFromDate:date];
        NSString * fileName = [NSString stringWithFormat:@"%@/%@.mov",cacheStr,currentTime];
        if ([data writeToFile:fileName atomically:YES]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.navigationBarHidden = NO;
                self.navigationBar.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 64);
                self.videoPickerSuccess(fileName, self.sourceType, videoImage, duration);
            });
        }else{
            NSLog(@"选取失败");
        }
    });
}

#pragma mark - 获取截图
-(UIImage *)getImage:(NSString *)videoURL{
    AVURLAsset * asset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:videoURL] options:nil];
    AVAssetImageGenerator * gen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    gen.appliesPreferredTrackTransform = YES;
    CMTime time = CMTimeMakeWithSeconds(0.5, 600); // 参数( 截取的秒数， 视频每秒多少帧)
    NSError * error = nil;
    CMTime actualTime;
    CGImageRef image = [gen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage * thumb = [[UIImage alloc] initWithCGImage:image];
    CGImageRelease(image);
    return thumb;
}

#pragma mark - 保存到相册成功后的回调
-(void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{
    if (!error) {
        NSLog(@"保存相册成功");
    }
}

#pragma mark - 选取取消后的回调
-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    self.videoPickerCancle(self.sourceType);
}

@end
