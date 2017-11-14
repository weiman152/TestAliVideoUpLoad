//
//  ViewController.m
//  TestAliVideoUpLoad
//
//  Created by weiman on 17/10/10.
//  Copyright © 2017年 whh. All rights reserved.
//

#import "ViewController.h"
#import "LRLVideoPickerController.h"
#import "AliUpLoad.h"
#import <CommonCrypto/CommonDigest.h>

#import "TZImagePickerController.h"

@interface ViewController ()<TZImagePickerControllerDelegate>

@property(nonatomic,strong)AliUpLoad * aliUpload;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    AliUpLoad * aliUpload = [AliUpLoad shareInstance];
    [aliUpload initAli];
    self.aliUpload = aliUpload;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)uploadOneFile:(id)sender {
    [self chooseFileFromPhotos];
}

- (IBAction)uploadMoreFile:(id)sender {
    
}

//从相册选取视频
-(void)chooseFileFromPhotos{
    __weak ViewController * weakSelf = self;
    LRLVideoPickerController * videoPicker = [[LRLVideoPickerController alloc] initWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary andvideoQuality:UIImagePickerControllerQualityTypeMedium];
    __weak LRLVideoPickerController * weakVideoPicker = videoPicker;
    videoPicker.videoPickerSuccess = ^(NSString * exportPath, UIImagePickerControllerSourceType sourceType, UIImage * videoImage, float videoDuration){
        NSLog(@"--------dddddd---------  %@",exportPath);
        [weakSelf uploadVideoWithFilePath:exportPath];
        [weakVideoPicker dismissViewControllerAnimated:YES completion:nil];
    };
    
    videoPicker.videoPickerCancle = ^(UIImagePickerControllerSourceType sourceType){
        [weakVideoPicker dismissViewControllerAnimated:YES completion:nil];
    };
    [self presentViewController:videoPicker animated:YES completion:nil];

}

-(void)uploadVideoWithFilePath:(NSString *)filePath{
    //获取系统当前时间毫秒数  想取得微秒时 用取到的时间戳 * 1000 * 1000
    UInt64 recordTime = [[NSDate date] timeIntervalSince1970]*1000;
    //拼接objectKey为用户名+时间戳
    NSString * nameStr=[NSString stringWithFormat:@"%lld",recordTime];
    //加密
    NSString * encryptObjectKey=[self creatMD5StringWithString:nameStr];
    //拼接上传相对路径
    NSString * objectKey=[NSString stringWithFormat:@"mobile/%@",encryptObjectKey];
    [self.aliUpload uploadFileWithBucketName:@"fz-video-edit" andObjectName:objectKey andFilePath:filePath];
}

#pragma mark-MD5加密
- (NSString *)creatMD5StringWithString:(NSString *)string
{
    const char *original_str = [string UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(original_str, (CC_LONG)strlen(original_str), result);
    NSMutableString *hash = [NSMutableString string];
    for (int i = 0; i < 16; i++)
        [hash appendFormat:@"%02X", result[i]];
    [hash lowercaseString];
    return hash;
}


- (IBAction)testTZ:(id)sender {
    
    TZImagePickerController *imagePickerVc = [[TZImagePickerController alloc] initWithMaxImagesCount:9 delegate:self];
    [self presentViewController:imagePickerVc animated:YES completion:nil];
    
}

#pragma mark - TZImagePickerControllerDelegate
-(void)imagePickerController:(TZImagePickerController *)picker didFinishPickingVideo:(UIImage *)coverImage sourceAssets:(id)asset{
    NSLog(@"aaaaaaaaaaaaa");
}

-(void)imagePickerController:(TZImagePickerController *)picker didFinishPickingPhotos:(NSArray<UIImage *> *)photos sourceAssets:(NSArray *)assets isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto{
    NSLog(@"bbbbbbbbbbbb");
}

-(void)imagePickerController:(TZImagePickerController *)picker didFinishPickingPhotos:(NSArray<UIImage *> *)photos sourceAssets:(NSArray *)assets isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto infos:(NSArray<NSDictionary *> *)infos{
    NSLog(@"cccccccccccc");
}

- (IBAction)selectVideo:(id)sender {
    TZImagePickerController *imagePickerVc = [[TZImagePickerController alloc] initWithMaxImagesCount:3 delegate:self];
    imagePickerVc.allowPickingVideo = YES;
    imagePickerVc.allowPickingImage = NO;
    //imagePickerVc.allowPickingMultipleVideo = YES;
    [self presentViewController:imagePickerVc animated:YES completion:nil];
}

- (IBAction)selectPhotos:(id)sender {
    TZImagePickerController *imagePickerVc = [[TZImagePickerController alloc] initWithMaxImagesCount:3 delegate:self];
    imagePickerVc.allowPickingVideo = NO;
    imagePickerVc.allowPickingImage = YES;
    [self presentViewController:imagePickerVc animated:YES completion:nil];

}


@end
