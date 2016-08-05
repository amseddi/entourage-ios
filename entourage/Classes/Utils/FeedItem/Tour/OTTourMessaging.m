//
//  OTTourMessaging.m
//  entourage
//
//  Created by sergiu buceac on 7/18/16.
//  Copyright © 2016 OCTO Technology. All rights reserved.
//

#import "OTTourMessaging.h"
#import "OTTourService.h"

@implementation OTTourMessaging

- (void)send:(NSString *)message withSuccess:(void (^)(OTTourMessage *))success orFailure:(void (^)(NSError *))failure {
    [[OTTourService new] sendMessage:message
                              onTour:self.tour
                             success:^(OTTourMessage * tourMessage) {
                                 NSLog(@"CHAT %@", message);
                                 if(success)
                                     success(tourMessage);
                             } failure:^(NSError *error) {
                                 NSLog(@"CHATerr: %@", error.description);
                                 if(failure)
                                     failure(error);
                             }];
}

- (void)invitePhones:(NSArray *)phones withSuccess:(void (^)())success orFailure:(void (^)(NSError *, NSArray *))failure {
    // NOT IN THS VERSION (maybe 2.0)
}

@end
