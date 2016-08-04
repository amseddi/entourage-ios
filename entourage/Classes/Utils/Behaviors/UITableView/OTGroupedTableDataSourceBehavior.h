//
//  OTGroupedTableSourceBehavior.h
//  entourage
//
//  Created by sergiu buceac on 7/29/16.
//  Copyright © 2016 OCTO Technology. All rights reserved.
//

#import "OTBehavior.h"
#import "OTTableDataSourceBehavior.h"

@interface OTGroupedTableDataSourceBehavior : OTTableDataSourceBehavior

@property (nonatomic, strong) NSDictionary *groupedSource;
@property (nonatomic, strong) NSArray *quickJumpList;

@end