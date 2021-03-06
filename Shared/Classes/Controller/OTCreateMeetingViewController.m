//
//  OTCreateMeetingViewController.m
//  entourage
//
//  Created by Hugo Schouman on 11/10/2014.
//  Copyright (c) 2014 OCTO Technology. All rights reserved.
//

#import <SVProgressHUD/SVProgressHUD.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import <Social/Social.h>

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
#import "OTEncounterDisclaimerBehavior.h"
#import "OTTextWithCount.h"
#import "OTLocationSelectorViewController.h"
#import "NSError+OTErrorData.h"
#import "OTJSONResponseSerializer.h"
#import "OTFeedItemFactory.h"
#import "OTOngoingTourService.h"
#import "entourage-Swift.h"

#define PADDING 20.0f

@interface OTCreateMeetingViewController () <LocationSelectionDelegate>

@property (strong, nonatomic) NSString *lmPath;
@property (strong, nonatomic) NSString *dicPath;
@property (nonatomic) CLLocationCoordinate2D location;
@property (nonatomic, strong) IBOutlet UITextField *nameTextField;
@property (nonatomic, strong) IBOutlet OTTextWithCount *messageTextView;
@property (weak, nonatomic) IBOutlet UILabel *firstLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (strong, nonatomic) IBOutlet OTEncounterDisclaimerBehavior *disclaimer;
@property (nonatomic, weak) IBOutlet UIButton *locationButton;

@end

@implementation OTCreateMeetingViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    [UIApplication sharedApplication].delegate.window.backgroundColor = [UIColor colorWithRed:239 green:239 blue:244 alpha:1];
    
    self.title = OTLocalizedString(@"descriptionTitle").uppercaseString;
    [self setupUI];
    if(!self.encounter && self.displayedOnceForTour) {
        [self.disclaimer showDisclaimer];
    }
    else {
        self.nameTextField.text = self.encounter.streetPersonName;
        self.messageTextView.textView.text = self.encounter.message;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.messageTextView.textView.text && ![self.messageTextView.textView.text isEqualToString: @""])
        [self.messageTextView updateAfterSpeech];
}

#pragma mark - Private methods

- (void)setupUI {
    [self setupCloseModal];

    [OTAppConfiguration configureNavigationControllerAppearance:self.navigationController];
    
    UIBarButtonItem *menuButton = [UIBarButtonItem createWithTitle:OTLocalizedString(@"validate")
                                                            withTarget:self
                                                             andAction:@selector(sendEncounter:)
                                                               andFont:@"SFUIText-Bold"
                                                               colored:[ApplicationTheme shared].secondaryNavigationBarTintColor];
        [self.navigationItem setRightBarButtonItem:menuButton];
    
    OTUser *currentUser = [[NSUserDefaults standardUserDefaults] currentUser];
    self.firstLabel.text = [NSString stringWithFormat:OTLocalizedString(@"formater_encounterAnd"), currentUser.displayName];
    
    [self.nameTextField indentWithPadding:PADDING];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd/MM/yyyy"];
    
    NSString *dateString = [formatter stringFromDate:[NSDate date]];
    self.dateLabel.text = [NSString stringWithFormat:OTLocalizedString(@"formater_meetEncounter"), dateString];
    
    self.messageTextView.placeholder = OTLocalizedString(@"detailEncounter");
    if(self.encounter != nil) {
        CLLocation *encounterLocation = [[CLLocation alloc] initWithLatitude:self.encounter.latitude
                                                                   longitude:self.encounter.longitude];
        self.location = encounterLocation.coordinate;
    }
    [self updateLocationTitle];
}

- (void)updateLocationTitle {
    CLGeocoder *geocoder = [CLGeocoder new];
    CLLocation *current = [[CLLocation alloc] initWithLatitude:self.location.latitude
                                             longitude:self.location.longitude];
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
    [OTLogger logEvent:@"ValidateEncounterClick"];
    if(self.nameTextField.text.length == 0) {
        UIAlertController *controller = [UIAlertController alertControllerWithTitle:@""
                                                                            message:OTLocalizedString(@"encounter_enter_name_of_met_person")
                                                                     preferredStyle:UIAlertControllerStyleAlert];
        [controller addAction:[UIAlertAction actionWithTitle:OTLocalizedString(@"tryAgain_short") style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:controller animated:YES completion:nil];
        return;
    }
    else if(self.messageTextView.textView.text.length == 0) {
        UIAlertController *controller = [UIAlertController alertControllerWithTitle:@""
                                                                            message:OTLocalizedString(@"encounter_fill_all_fields")
                                                                     preferredStyle:UIAlertControllerStyleAlert];
        [controller addAction:[UIAlertAction actionWithTitle:OTLocalizedString(@"tryAgain_short") style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:controller animated:YES completion:nil];
        return;
    }
    if(!self.encounter)
        [self createEncounter:sender];
    else
        [self updateEncounter:sender];
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
        [OTLogger logEvent:@"ChangeLocationClick"];
        OTLocationSelectorViewController* controller = (OTLocationSelectorViewController *)destinationViewController;
        controller.locationSelectionDelegate = self;
        CLLocation *current = [[CLLocation alloc] initWithLatitude:self.location.latitude longitude:self.location.longitude];
        controller.selectedLocation = current;
    }
}

#pragma mark - private methods
- (void)createEncounter:(UIBarButtonItem*)sender  {
    sender.enabled = NO;
    __block OTEncounter *encounter = [OTEncounter new];
    encounter.date = [NSDate date];
    encounter.message = self.messageTextView.textView.text;
    encounter.streetPersonName =  self.nameTextField.text;
    encounter.latitude = self.location.latitude;
    encounter.longitude = self.location.longitude;
    [SVProgressHUD show];
    [[OTEncounterService new] sendEncounter:encounter
                                 withTourId:self.currentTourId
                                withSuccess:^(OTEncounter *sentEncounter) {
                                    [SVProgressHUD showSuccessWithStatus:OTLocalizedString(@"meetingCreated")];
                                    [self.delegate encounterSent:sentEncounter];
                                }
                                    failure:^(NSError *error) {
                                        [SVProgressHUD showErrorWithStatus:OTLocalizedString(@"meetingNotCreated")];
                                        sender.enabled = YES;
                                    }];
}

- (void)updateEncounter:(UIBarButtonItem*)sender {
    sender.enabled = NO;
    self.encounter.streetPersonName = self.nameTextField.text;
    self.encounter.message = self.messageTextView.textView.text;
    self.encounter.latitude = self.location.latitude;
    self.encounter.longitude = self.location.longitude;
   
    [SVProgressHUD show];
    [[OTEncounterService new] updateEncounter:self.encounter
                                  withSuccess:^(OTEncounter *updatedEncounter) {
                                      [SVProgressHUD showSuccessWithStatus:OTLocalizedString(@"meetingUpdated")];
                                      [self.delegate encounterSent:self.encounter];
                                  }
                                      failure:^(NSError *error) {
                                          [SVProgressHUD showErrorWithStatus:OTLocalizedString(@"meetingNotUpdated")];
                                          sender.enabled = YES;
                                      }];
}

@end
