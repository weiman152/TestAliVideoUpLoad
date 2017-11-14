//
//  AliUpLoad.h
//  TestAliVideoUpLoad
//
//  Created by weiman on 17/10/11.
//  Copyright © 2017年 whh. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AliUpLoad : NSObject

+(instancetype)shareInstance;

-(void)initAli;

-(void)uploadFileWithBucketName:(NSString *)bucketName andObjectName:(NSString *)objectName andFilePath:(NSString *)filePath;

@end
