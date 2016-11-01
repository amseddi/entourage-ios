//
//  OTCreateMeetingViewController.m
//  entourage
//
//  Created by Hugo Schouman on 11/10/2014.
//  Copyright (c) 2014 OCTO Technology. All rights reserved.
//

#import "OTCreateMeetingViewController.h"
#import "OTMainViewController.h"
#import "OTEncounter.h"
#import "OTUser.h"
#import "OTConsts.h"
#import "OTPoiService.h"
#import "OTEncounterService.h"
#import "NSUserDefaults+OT.h"
#import "UITextField+indentation.h"
#import "UIViewController+menu.h"
#import "UIColor+entourage.h"
#import "UIBarButtonItem+factory.h"
#import "MBProgressHUD.h"
#import "SVProgressHUD.h"
#import <Social/Social.h>
#import "OTSpeechBehavior.h"
#import "OTEncounterDisclaimerBehavior.h"
#import "OTTextWithCount.h"
#import "OTLocationSelectorViewController.h"
#import "NSError+OTErrorData.h"
#import "OTJSONResponseSerializer.h"

#define PADDING 20.0f

@interface OTCreateMeetingViewController () <LocationSelectionDelegate>

@property (strong, nonatomic) NSNumber *currentTourId;
@property (strong, nonatomic) NSString *lmPath;
@property (strong, nonatomic) NSString *dicPath;
@property (nonatomic) CLLocationCoordinate2D location;

@property (nonatomic, strong) IBOutlet UITextField *nameTextField;
@property (nonatomic, strong) IBOutlet OTTextWithCount *messageTextView;
@property (weak, nonatomic) IBOutlet UILabel *firstLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (strong, nonatomic) IBOutlet OTSpeechBehavior *speechBehavior;
@property (strong, nonatomic) IBOutlet OTEncounterDisclaimerBehavior *disclaimer;
@property (nonatomic, weak) IBOutlet UIButton *locationButton;

@end

@implementation OTCreateMeetingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = OTLocalizedString(@"descriptionTitle").uppercaseString;
    [self setupUI];
    [self.speechBehavior initialize];
    [self.disclaimer showDisclaimer];
}

#pragma mark - Private methods

- (void)setupUI {
    [self setupCloseModal];
    
    UIBarButtonItem *menuButton = [UIBarButtonItem createWithTitle:OTLocalizedString(@"validate") withTarget:self andAction:@selector(sendEncounter:) colored:[UIColor appOrangeColor]];
    [self.navigationItem setRightBarButtonItem:menuButton];
    
    OTUser *currentUser = [[NSUserDefaults standardUserDefaults] currentUser];
    self.firstLabel.text = [NSString stringWithFormat:OTLocalizedString(@"formater_encounterAnd"), currentUser.displayName];
    
    [self.nameTextField indentWithPadding:PADDING];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd/MM/yyyy"];
    
    NSString *dateString = [formatter stringFromDate:[NSDate date]];
    self.dateLabel.text = [NSString stringWithFormat:OTLocalizedString(@"formater_meetEncounter"), dateString];
    
    self.messageTextView.placeholder = OTLocalizedString(@"detailEncounter");
    self.messageTextView.editingPlaceholder = self.messageTextView.placeholder;

    [self updateLocationTitle];
}

- (void)updateLocationTitle {
    CLGeocoder *geocoder = [CLGeocoder new];
    CLLocation *current = [[CLLocation alloc] initWithLatitude:self.location.latitude longitude:self.location.longitude];
    [geocoder reverseGeocodeLocation:current completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        if (error)
            NSLog(@"error: %@", error.description);
        CLPlacemark *placemark = placemarks.firstObject;
        if (placemark.thoroughfare !=  nil)
            [self.locationButton setTitle:placemark.thoroughfare forState:UIControlStateNormal];
        else
            [self.locationButton setTitle:placemark.locality forState:UIControlStateNormal];
    }];
}

- (void)configureWithTourId:(NSNumber *)currentTourId andLocation:(CLLocationCoordinate2D)location {
    self.currentTourId = currentTourId;
	self.location = location;
}

- (IBAction)sendEncounter:(UIBarButtonItem*)sender {
    [Flurry logEvent:@"ValidateEncounterClick"];
    sender.enabled = NO;
    __block OTEncounter *encounter = [OTEncounter new];
    encounter.date = [NSDate date];
    encounter.message = self.messageTextView.textView.text;
    encounter.streetPersonName =  self.nameTextField.text;
    encounter.latitude = self.location.latitude;
    encounter.longitude = self.location.longitude;
    [SVProgressHUD show];
    [[OTEncounterService new] sendEncounter:encounter withTourId:self.currentTourId withSuccess:^(OTEncounter *sentEncounter) {
        [SVProgressHUD showSuccessWithStatus:OTLocalizedString(@"meetingCreated")];
        [self.encounters addObject:encounter];
        [self.delegate encounterSent:encounter];
    }
    failure:^(NSError *error) {
        NSString *message = OTLocalizedString(@"meetingNotCreated");
        NSString *reason = [self readReason:error];
        if(reason && reason.length > 0)
            message = reason;
        [SVProgressHUD showErrorWithStatus:message];
        sender.enabled = YES;
    }];
}

#pragma mark - LocationSelectionDelegate

- (void)didSelectLocation:(CLLocation *)selectedLocation {
    self.location = selectedLocation.coordinate;
    [self updateLocationTitle];
}

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([self.disclaimer prepareSegue:segue])
        return;
    
    UIViewController *destinationViewController = segue.destinationViewController;
    if ([destinationViewController isKindOfClass:[OTLocationSelectorViewController class]]) {
        [Flurry logEvent:@"ChangeLocationClick"];
        OTLocationSelectorViewController* controller = (OTLocationSelectorViewController *)destinationViewController;
        controller.locationSelectionDelegate = self;
        CLLocation *current = [[CLLocation alloc] initWithLatitude:self.location.latitude longitude:self.location.longitude];
        controller.selectedLocation = current;
    }
}

#pragma mark - error read

- (NSString *)readReason:(NSError *)error {
    id fullContent = [error.userInfo objectForKey:JSONResponseSerializerFullDictKey];
    if([fullContent isKindOfClass:[NSDictionary class]]) {
        id reasons = [fullContent objectForKey:@"reasons"];
        if([reasons isKindOfClass:[NSArray class]]) {
            NSArray *reasonsArray = (NSArray *)reasons;
            if(reasonsArray.count > 0)
                return reasonsArray[0];
        }
    }
    return @"";
}

@end
