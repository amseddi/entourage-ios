//
//  OTSummaryProviderBehavior.m
//  entourage
//
//  Created by sergiu buceac on 8/2/16.
//  Copyright © 2016 OCTO Technology. All rights reserved.
//

#import "OTSummaryProviderBehavior.h"
#import "UIButton+entourage.h"
#import "OTFeedItemFactory.h"
#import "OTUIDelegate.h"

@implementation OTSummaryProviderBehavior

- (void)awakeFromNib {
    if(!self.fontSize)
        self.fontSize = [NSNumber numberWithFloat:DEFAULT_DESCRIPTION_SIZE];
}

- (void)configureWith:(OTFeedItem *)feedItem {
    id<OTUIDelegate> uiDelegate = [[OTFeedItemFactory createFor:feedItem] getUI];
    if(self.lblTitle)
        self.lblTitle.text = [uiDelegate summary];
    if(self.lblUserCount)
        self.lblUserCount.text = [feedItem.noPeople stringValue];
    if(self.btnAvatar)
        [self.btnAvatar setupAsProfilePictureFromUrl:feedItem.author.avatarUrl];
    if(self.lblDescription)
        [self.lblDescription setAttributedText:[uiDelegate descriptionWithSize:self.fontSize.floatValue]];
    if(self.lblTimeDistance) {
    self.lblTimeDistance.text = @"";
        [uiDelegate timeDataWithCompletion:^(NSString *result) {
            self.lblTimeDistance.text = result;
        }];
    }
}

@end