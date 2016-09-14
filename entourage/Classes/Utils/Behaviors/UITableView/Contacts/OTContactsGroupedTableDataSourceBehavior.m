//
//  OTContactsGroupedTableDataSourceBehavior.m
//  entourage
//
//  Created by sergiu buceac on 7/29/16.
//  Copyright © 2016 OCTO Technology. All rights reserved.
//

#import "OTContactsGroupedTableDataSourceBehavior.h"
#import "OTAddressBookItem.h"
#import "OTDataSourceBehavior.h"

@implementation OTContactsGroupedTableDataSourceBehavior

- (void)refresh {
    NSMutableArray *sections = [NSMutableArray new];
    NSMutableArray *headers = [NSMutableArray new];
    NSString *index = nil;
    NSUInteger section = -1;
    for (OTAddressBookItem *item in self.dataSource.items) {
        NSString *currentIndex = [item.fullName substringToIndex:1];
        if(!index || ![index isEqualToString:currentIndex]) {
            [headers addObject:currentIndex];
            [sections addObject:[NSMutableArray new]];
            index = currentIndex;
            section++;
        }
        NSMutableArray *array = sections[section];
        [array addObject:item];
    }
    self.groupedSource = sections;
    self.groupHeaders = headers;
    [self.dataSource.tableView reloadData];
}

@end
