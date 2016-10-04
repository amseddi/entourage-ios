//
//  OTStatusBehavior.m
//  entourage
//
//  Created by sergiu buceac on 8/4/16.
//  Copyright © 2016 OCTO Technology. All rights reserved.
//

#import "OTStatusBehavior.h"
#import "OTUser.h"
#import "NSUserDefaults+OT.h"
#import "OTFeedItemFactory.h"
#import "OTConsts.h"
#import "UIColor+entourage.h"
#import "OTTour.h"

#define BUTTON_NOTREQUESTED @"joinButton"
#define BUTTON_PENDING      @"pendingRequestButton"
#define BUTTON_ACCEPTED     @"activeButton"
#define BUTTON_REJECTED     @"refusedRequestButton"

@interface OTStatusBehavior ()

@property (nonatomic, strong) OTFeedItem *feedItem;
@property (nonatomic, strong) OTUser *currentUser;

@end

@implementation OTStatusBehavior

- (void)initialize {
    self.currentUser = [NSUserDefaults standardUserDefaults].currentUser;
}

- (void)updateWith:(OTFeedItem *)feedItem {
    self.feedItem = feedItem;
    self.btnStatus.hidden = self.lblStatus.hidden = ![[[OTFeedItemFactory createFor:self.feedItem] getStateInfo] isActive];
    if(self.btnStatus.hidden)
        return;
    [self updateButton];
    [self updateLabel];
}

#pragma mark - private methods

- (void)updateButton {
    if (self.feedItem.author.uID.intValue == self.currentUser.sid.intValue)
        [self.btnStatus setImage:[UIImage imageNamed:@"activeButton"] forState:UIControlStateNormal];
    else {
        if ([JOIN_ACCEPTED isEqualToString:self.feedItem.joinStatus])
            [self.btnStatus setImage:[UIImage imageNamed:@"activeButton"] forState:UIControlStateNormal];
        else if ([JOIN_PENDING isEqualToString:self.feedItem.joinStatus])
            [self.btnStatus setImage:[UIImage imageNamed:@"pendingRequestButton"] forState:UIControlStateNormal];
        else if ([JOIN_REJECTED isEqualToString:self.feedItem.joinStatus])
            [self.btnStatus setImage:[UIImage imageNamed:@"refusedRequestButton"] forState:UIControlStateNormal];
        else
            [self.btnStatus setImage:[UIImage imageNamed:@"joinButton"] forState:UIControlStateNormal];
    }
}

- (void)updateLabel {
    if (self.feedItem.author.uID.intValue == self.currentUser.sid.intValue)
        if([self.feedItem.status isEqualToString:TOUR_STATUS_ONGOING])
            [self updateLabelWithText:OTLocalizedString(@"ongoing") andColor:[UIColor appOrangeColor]];
        else
            [self updateLabelWithText:OTLocalizedString(@"join_active") andColor:[UIColor appOrangeColor]];
    else {
        if ([JOIN_ACCEPTED isEqualToString:self.feedItem.joinStatus])
            [self updateLabelWithText:OTLocalizedString(@"join_active") andColor:[UIColor appOrangeColor]];
        else if ([JOIN_PENDING isEqualToString:self.feedItem.joinStatus])
            [self updateLabelWithText:OTLocalizedString(@"join_pending") andColor:[UIColor appOrangeColor]];
        else if ([JOIN_REJECTED isEqualToString:self.feedItem.joinStatus])
            [self updateLabelWithText:OTLocalizedString(@"join_rejected") andColor:[UIColor appTomatoColor]];
        else
            [self updateLabelWithText:OTLocalizedString(@"join_to_join") andColor:[UIColor appGreyishColor]];
    }
}

- (void)updateLabelWithText:(NSString *)text andColor:(UIColor *)color {
    [self.lblStatus setText:text];
    [self.lblStatus setTextColor:color];
}

@end
