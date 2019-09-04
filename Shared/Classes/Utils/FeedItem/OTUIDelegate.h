//
//  OTUIDelegate.h
//  entourage
//
//  Created by sergiu buceac on 8/2/16.
//  Copyright © 2016 OCTO Technology. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTAPIConsts.h"

@protocol OTUIDelegate <NSObject>

- (NSAttributedString *) descriptionWithSize:(CGFloat)size;
- (NSString *)descriptionWithoutUserName;
- (NSString *)userName;
- (NSString *)summary;
- (NSString *)categoryIconSource;
- (NSString *)feedItemDescription;

@optional
- (NSString *)navigationTitle;
- (NSString *)contentImageUrl;
- (NSString *)joinAcceptedText;
- (double)distance;
- (BOOL)isStatusBtnVisible;
- (NSString *)feedItemActionButton;
- (NSAttributedString *)eventAuthorFormattedDescription;
- (NSString *)eventInfoDescription;
- (NSAttributedString *)eventInfoFormattedDescription;
- (NSString *)formattedTimestamps;

@end
