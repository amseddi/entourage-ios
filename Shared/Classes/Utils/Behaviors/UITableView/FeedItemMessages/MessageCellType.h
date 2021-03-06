//
//  MessageCellType.h
//  entourage
//
//  Created by sergiu buceac on 8/8/16.
//  Copyright © 2016 OCTO Technology. All rights reserved.
//

typedef NS_ENUM(long) {
    MessageCellTypeNone,
    MessageCellTypeSent,
    MessageCellTypeReceived,
    MessageCellTypeJoinRequested,
    MessageCellTypeJoinRequestedNotOwner,
    MessageCellTypeJoinAccepted,
    MessageCellTypeJoinRejected,
    MessageCellTypeEncounter,
    MessageCellTypeStatus,
    MessageCellTypeChatDate,
    MessageCellTypeEventCreated,
    MessageCellTypeItemClosed
} MessageCellType;
