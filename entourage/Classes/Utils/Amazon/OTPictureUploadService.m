//
//  OTPictureUploadService.m
//  entourage
//
//  Created by sergiu buceac on 7/13/16.
//  Copyright © 2016 OCTO Technology. All rights reserved.
//

#import "OTPictureUploadService.h"
#import "AWSCore.h"
#import "AWSS3.h"
#import "AWSServiceEnum.h"
#import "AWSS3Service.h"
#import "OTApiConsts.h"
#import "NSUserDefaults+OT.h"
#import "OTUser.h"
#import "entourage-Swift.h"

#define PICTURE_BUCKET @"entourage-avatars-production-thumb"

@implementation OTPictureUploadService

+ (void)configure {
    NSString *amazonAccessKey = [[ConfigurationManager shared] amazonAccessKey];
    NSString *amazonSecretKey = [[ConfigurationManager shared] amazonSecretKey];
    AWSStaticCredentialsProvider *staticProvider = [[AWSStaticCredentialsProvider alloc] initWithAccessKey:amazonAccessKey
                                                                                                 secretKey:amazonSecretKey];
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionEUWest1 credentialsProvider:staticProvider];
    AWSServiceManager.defaultServiceManager.defaultServiceConfiguration = configuration;
}

- (void)uploadPicture:(UIImage *)picture withSuccess:(void (^)(NSString *))success orError:(void (^)(NSError *))error {
        NSURL *toUpload = [self saveToFile:picture];
        NSString *fileName = [NSString stringWithFormat:@"user_%@.jpg", USER_ID];
        AWSS3TransferManagerUploadRequest *uploadRequest = [self buildUploadRequestFor:toUpload withName:fileName];
        AWSS3TransferManager *transferManager = [AWSS3TransferManager defaultS3TransferManager];
        [[transferManager upload:uploadRequest] continueWithBlock:^id(AWSTask *task) {
            [self removeFile:toUpload];
            if(task.completed && !task.cancelled && success)
                success(fileName);
            if(task.faulted)
                error(task.error);
            return nil;
        }];
}

- (AWSS3TransferManagerUploadRequest *)buildUploadRequestFor:(NSURL *)fileUri withName:(NSString *)fileName {
    AWSS3TransferManagerUploadRequest *uploadRequest = [AWSS3TransferManagerUploadRequest new];
    uploadRequest.bucket = PICTURE_BUCKET;
    uploadRequest.key = [[ConfigurationManager shared].amazonPictureFolder stringByAppendingString:fileName];
    uploadRequest.body = fileUri;
    uploadRequest.contentType = @"image/jpeg";
    return uploadRequest;
}

- (NSURL *)saveToFile:(UIImage *)image {
    NSString *fileName = [[[NSUUID UUID] UUIDString] stringByAppendingPathExtension:@"jpg"];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:fileName];
    [UIImageJPEGRepresentation(image, 1) writeToFile:filePath atomically:YES];
    return [NSURL fileURLWithPath:filePath];
}

- (void)removeFile:(NSURL *)fileUri {
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:[fileUri path] error:&error];
    if (error)
        NSLog(@"Can't remove local uploaded file: %@", error);
}

@end
