//
//  OTDeepLinkService.m
//  entourage
//
//  Created by sergiu buceac on 8/17/16.
//  Copyright © 2016 OCTO Technology. All rights reserved.
//

#import "OTDeepLinkService.h"
#import "OTAppDelegate.h"
#import "OTActiveFeedItemViewController.h"
#import "OTSWRevealViewController.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "OTFeedItemFactory.h"
#import "OTUserViewController.h"
#import "OTPublicFeedItemViewController.h"
#import "OTAPIConsts.h"
#import "NSUserDefaults+OT.h"
#import "OTEntourageEditorViewController.h"
#import "OTTutorialViewController.h"
#import "OTSafariService.h"
#import "OTAPIErrorDomain.h"

@interface OTDeepLinkService ()

@property (nonatomic, weak) NSURL *link;

@end

@implementation OTDeepLinkService

- (void)navigateToFeedWithNumberId:(NSNumber *)feedItemId
                          withType:(NSString *)feedItemType {
    [SVProgressHUD show];
    [[[OTFeedItemFactory createForType:feedItemType andId:feedItemId] getStateInfo] loadWithSuccess3:^(OTFeedItem *feedItem) {
        [SVProgressHUD dismiss];
        [self prepareControllers:feedItem];
    } error:^(NSError *error) {
        [SVProgressHUD dismiss];
    }];
}
                     
- (void)navigateToFeedWithNumberId:(NSNumber *)feedItemId
                          withType:(NSString *)feedItemType
                         groupType:(NSString*)groupType {
    [SVProgressHUD show];
    
    BOOL isTour = [feedItemType isEqualToString:TOUR_TYPE_NAME];
    id stateInfo = nil;
    if (isTour) {
        stateInfo = [[OTFeedItemFactory createForType:feedItemType andId:feedItemId] getStateInfo];
    } else {
        stateInfo = [[OTFeedItemFactory createEntourageForGroupType:groupType andId:feedItemId] getStateInfo];
    }
    
    if (stateInfo && feedItemId) {
        [stateInfo loadWithSuccess3:^(OTFeedItem *feedItem) {
            [SVProgressHUD dismiss];
            [self prepareControllers:feedItem];
        } error:^(NSError *error) {
            [SVProgressHUD dismiss];
        }];
    }
}

- (void)navigateToFeedWithStringId: (NSString *)feedItemId {
    [SVProgressHUD show];
    if (TOKEN) {
        [[[OTFeedItemFactory createForId:feedItemId] getStateInfo] loadWithSuccess2:^(OTFeedItem *feedItem) {
        [SVProgressHUD dismiss];
        [self prepareControllers:feedItem];
        } error:^(NSError *error) {
            [SVProgressHUD dismiss];
            if ([error.domain isEqual:OTApiErrorDomain] && error.code == OTApiErrorAnonymousUserAuthenticationRequired) {
                [OTAppState presentAuthenticationOverlay:[self getTopViewController]];
            }
        }];
    }
    else {
        [OTAppState navigateToLoginScreen:nil sender:nil];
        [SVProgressHUD dismiss];
    }
}

- (UIViewController *)getTopViewController {
    return [OTAppState getTopViewController];
}

- (void)showProfileFromAnywhereForUser:(NSString *)userId {
    OTUser *currentUser = [NSUserDefaults standardUserDefaults].currentUser;
    if (currentUser.isAnonymous && [userId isEqualToString:currentUser.uuid]) {
        OTMainViewController *mainViewController = [self popToMainViewController];
        [OTAppState presentAuthenticationOverlay:mainViewController];
        return;
    }

    UIStoryboard *userProfileStorybard = [UIStoryboard storyboardWithName:@"UserProfile" bundle:nil];
    UINavigationController *rootUserProfileController = (UINavigationController *)[userProfileStorybard instantiateInitialViewController];
    OTUserViewController *userController = (OTUserViewController *)rootUserProfileController.topViewController;
    userController.userId = [NSNumber numberWithInteger:userId.integerValue];
    
    [self showControllerFromAnywhere:rootUserProfileController];
}

- (void) handleDeepLink: (NSURL *)url {
    NSString *host = url.host;
    NSString *query = url.query;
    self.link = url;
    if (!TOKEN) {
        [OTAppState navigateToLoginScreen:url sender:nil];
    } else {
        [self handleDeepLinkWithKey:host pathComponents:url.pathComponents andQuery:query];
    }
}

+ (BOOL)isUniversalLink:(NSURL *)url {
    return ([@[@"http", @"https"] containsObject:url.scheme] &&
            [@[@"entourage.social", @"www.entourage.social"] containsObject:url.host]);
}

- (void)handleUniversalLink:(NSURL *)url {
    if (url.pathComponents == nil || url.pathComponents.count < 2) return;
    NSMutableArray *pathComponents = [NSMutableArray arrayWithArray:url.pathComponents];
    
    // remove the leading '/'
    [pathComponents removeObjectAtIndex:0];
    
    // handle the 'entourages/<extra>'
    NSString *key = [pathComponents objectAtIndex:0];
    if ([key isEqualToString:@"entourages"]) {
        [self handleDeepLinkWithKey:key pathComponents:pathComponents andQuery:nil];
    }
    else if ([key isEqualToString:@"deeplink"]) {
        // handle the 'deeplink/<key>/<extra>?<query>'
        // remove the 'deeplink'
        [pathComponents removeObjectAtIndex:0];
        
        // handle the deep link
        key = [pathComponents objectAtIndex:0];
        [self handleDeepLinkWithKey:key pathComponents:pathComponents andQuery:url.query];
    }
}

- (void)handleDeepLinkWithKey:(NSString *)key
               pathComponents:(NSArray *)pathComponents
                     andQuery:(NSString *)query {
    if ([key isEqualToString:@"feed"]) {
        OTMainViewController *mainViewController = [self popToMainViewController];

        // "feed/filters"
        if (pathComponents != nil && pathComponents.count >= 2) {
            if ([pathComponents[1] isEqualToString:@"filters"]) {
                [mainViewController showFilters];
            }
        }
    } else if ([key isEqualToString:@"webview"]) {
        NSArray *elts = [query componentsSeparatedByString:@"="];
        NSURL *url = [NSURL URLWithString:elts[1]];
        [self openWithWebView:url];
        
    } else if ([key isEqualToString:@"profile"]) {
        [self showProfileFromAnywhereForUser:[[NSUserDefaults standardUserDefaults] currentUser].uuid];
        
    } else if ([key isEqualToString:@"messages"]) {
        if ([NSUserDefaults standardUserDefaults].currentUser.isAnonymous) {
            OTMainViewController *mainViewController = [self popToMainViewController];
            [OTAppState presentAuthenticationOverlay:mainViewController];
            return;
        }

        UITabBarController *tabViewController = [OTAppConfiguration configureMainTabBarWithDefaultSelectedIndex:MESSAGES_TAB_INDEX];
        [self updateAppWindow:tabViewController];
        
    } else if ([key isEqualToString:@"create-action"]) {
        OTMainViewController *mainViewController = [self popToMainViewController];
        [OTAppState showFeedAndMapActionsFromController:mainViewController
                                            showOptions:NO
                                           withDelegate:mainViewController
                                         isEditingEvent:YES];
        
    } else if ([key isEqualToString:@"entourage"] || [key isEqualToString:@"entourages"]) {
        if (pathComponents != nil && pathComponents.count >= 2) {
            [self navigateToFeedWithStringId:pathComponents[1]];
        }
    } else if ([key isEqualToString:@"user"] || [key isEqualToString:@"users"]) {
        if (pathComponents != nil && pathComponents.count >= 2) {
            [self showProfileFromAnywhereForUser:pathComponents[1]];
        }
    } else if ([key isEqualToString:@"guide"]) {
        OTMainViewController *mainViewController = [self popToMainViewController];
        [mainViewController switchToGuide];
    }
    else if ([key isEqualToString:@"tutorial"]) {
        [OTAppState presentTutorialScreen];
    }
    else if([key isEqualToString:@"phone-settings"]) {
        dispatch_async(dispatch_get_main_queue(), ^() {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        });
    }
}

- (void)openWithWebView: (NSURL *)url {
    [OTSafariService launchInAppBrowserWithUrl:url viewController:nil];
}

- (UIViewController *)instatiateControllerWithStoryboardIdentifier: (NSString *)storyboardId
                                           andControllerIdentifier: (NSString *)controllerId {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardId bundle:nil];
    UIViewController *controller = [storyboard instantiateViewControllerWithIdentifier:controllerId];
    return controller;
}

- (void)showController: (UIViewController *)controller {
    UITabBarController *tabViewController = [OTAppConfiguration configureMainTabBarWithDefaultSelectedIndex:MAP_TAB_INDEX];
    [self updateAppWindow:tabViewController];
    
    UINavigationController *navigationController = (UINavigationController *)tabViewController.viewControllers[0];
    
    [navigationController pushViewController:controller animated:NO];
}

- (void)showControllerFromAnywhere:(UIViewController *)controller {
    OTMainViewController *mainViewController = [self popToMainViewController];
    [mainViewController presentViewController:controller animated:YES completion:nil];
}

- (OTMainViewController *)popToMainViewController {
    UITabBarController *tabViewController = [OTAppConfiguration configureMainTabBarWithDefaultSelectedIndex:MAP_TAB_INDEX];
    [self updateAppWindow:tabViewController];
    
    UINavigationController *navController = (UINavigationController*)tabViewController.viewControllers.firstObject;
    return (OTMainViewController*)navController.topViewController;
}

- (void)prepareControllers:(OTFeedItem *)feedItem {
    OTMainViewController *mainViewController = [self popToMainViewController];
    
    if (!feedItem) {
        return;
    }
    
    if ([[[OTFeedItemFactory createFor:feedItem] getStateInfo] isPublic]) {
        UIStoryboard *publicFeedItemStorybard = [UIStoryboard storyboardWithName:@"PublicFeedItem" bundle:nil];
        OTPublicFeedItemViewController *publicFeedItemController = (OTPublicFeedItemViewController *)[publicFeedItemStorybard instantiateInitialViewController];
        publicFeedItemController.feedItem = feedItem;
        
        [mainViewController.navigationController pushViewController:publicFeedItemController animated:NO];
    }
    else {
        UIStoryboard *activeFeedItemStorybard = [UIStoryboard storyboardWithName:@"ActiveFeedItem" bundle:nil];
        OTActiveFeedItemViewController *activeFeedItemController = (OTActiveFeedItemViewController *)[activeFeedItemStorybard instantiateInitialViewController];
        activeFeedItemController.feedItem = feedItem;
        
        [mainViewController.navigationController pushViewController:activeFeedItemController animated:NO];
    }
}

- (void)updateAppWindow:(UIViewController *)tabBarController {
    OTAppDelegate *appDelegate = (OTAppDelegate *)[[UIApplication sharedApplication] delegate];
    UIWindow *window = [appDelegate window];
    window.rootViewController = tabBarController;
    [window makeKeyAndVisible];
}

@end
