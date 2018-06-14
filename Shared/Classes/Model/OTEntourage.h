//
//  OTEntourage.h
//  entourage
//
//  Created by Ciprian Habuc on 13/05/16.
//  Copyright © 2016 OCTO Technology. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "OTFeedItem.h"
#import "OTCategory.h"
#import "OTConsts.h"

@interface OTEntourage : OTFeedItem

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *desc;
@property (nonatomic, strong) CLLocation *location;
@property (nonatomic, strong) NSString *category;
@property (nonatomic, strong) NSString *entourage_type;
@property (nonatomic, strong) OTCategory *categoryObject;

- (instancetype) initWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)dictionaryForWebService;

@end
