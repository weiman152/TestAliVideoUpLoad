//
//  AliUpLoad.m
//  TestAliVideoUpLoad
//
//  Created by weiman on 17/10/11.
//  Copyright © 2017年 whh. All rights reserved.
//

#import "AliUpLoad.h"
#import <AliyunOSSiOS/OSSService.h>

OSSClient * client;

@implementation AliUpLoad

+(instancetype)shareInstance{
    static AliUpLoad * instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [AliUpLoad new];
    });
    return instance;
}

-(void)initAli{
    NSString *endpoint = @"http://oss-cn-beijing.aliyuncs.com";

    // 移动端建议使用STS方式初始化OSSClient。更多鉴权模式请参考后面的访问控制章节。
    //id<OSSCredentialProvider> credential = [[OSSStsTokenCredentialProvider alloc] initWithAccessKeyId:@"LTAIDV8Zegj8XZs1" secretKeyId:@"RKXR9wGrIfO4fbhXXwwZDwB1Gm043T" securityToken:@"SecurityToken"];
    id<OSSCredentialProvider> credential = [[OSSPlainTextAKSKPairCredentialProvider alloc] initWithPlainTextAccessKey:@"LTAIDV8Zegj8XZs1" secretKey:@"RKXR9wGrIfO4fbhXXwwZDwB1Gm043T"];
    OSSClientConfiguration * conf = [OSSClientConfiguration new];
    conf.maxRetryCount = 3; // 网络请求遇到异常失败后的重试次数
    conf.timeoutIntervalForRequest = 30; // 网络请求的超时时间
    conf.timeoutIntervalForResource = 24 * 60 * 60; // 允许资源传输的最长时间
    client = [[OSSClient alloc] initWithEndpoint:endpoint credentialProvider:credential clientConfiguration:conf];

}

-(void)uploadFileWithBucketName:(NSString *)bucketName andObjectName:(NSString *)objectName andFilePath:(NSString *)filePath{
    OSSPutObjectRequest * put = [OSSPutObjectRequest new];
    put.bucketName = bucketName;
    put.objectKey = objectName;
    
    //put.uploadingData = [NSData dataWithContentsOfFile:filePath]; // 直接上传NSData
    put.uploadingFileURL = [NSURL fileURLWithPath:filePath];
    put.uploadProgress = ^(int64_t bytesSent, int64_t totalByteSent, int64_t totalBytesExpectedToSend) {
        NSLog(@"%lld, %lld, %lld", bytesSent, totalByteSent, totalBytesExpectedToSend);
        NSLog(@"------已上传--------------  %0.2f",(float)totalByteSent/(float)totalBytesExpectedToSend*1.0);
    };
    OSSTask * putTask = [client putObject:put];
    [putTask continueWithBlock:^id(OSSTask *task) {
        if (!task.error) {
            NSLog(@"upload object success!");
        } else {
            NSLog(@"upload object failed, error: %@" , task.error);
        }
        return nil;
    }];
    // 可以等待任务完成
    // [putTask waitUntilFinished];
    
}

@end








