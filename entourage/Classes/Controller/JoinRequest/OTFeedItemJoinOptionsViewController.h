//
//  OTFeedItemJoinOptionsViewController.h
//  entourage
//
//  Created by sergiu buceac on 9/12/16.
//  Copyright © 2016 OCTO Technology. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OTJoinDelegate.h"

@interface OTFeedItemJoinOptionsViewController : UIViewController

@property (nonatomic, weak) id<OTJoinDelegate> joinDelegate;

@end