//
//  OTDeepLinkService.h
//  entourage
//
//  Created by sergiu buceac on 8/17/16.
//  Copyright © 2016 OCTO Technology. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTMainViewController.h"

@interface OTDeepLinkService : NSObject

- (void)navigateToFeedWithNumberId:(NSNumber *)feedItemId
                          withType:(NSString *)feedItemType;

- (void)navigateToFeedWithStringId:(NSString *)feedItemId;

- (void)navigateToFeedWithNumberId:(NSNumber *)feedItemId
                          withType:(NSString *)feedItemType
                         groupType:(NSString*)groupType;

- (UIViewController *)getTopViewController;
- (OTMainViewController *)popToMainViewController;
- (void)showProfileFromAnywhereForUser:(NSString *)userId;
- (void)handleDeepLink:(NSURL *)url;
- (void)handleUniversalLink:(NSURL *)url;
- (void)openWithWebView: (NSURL *)url;

@end
