//
//  OTCodeViewController.m
//  entourage
//
//  Created by Ciprian Habuc on 07/07/16.
//  Copyright © 2016 OCTO Technology. All rights reserved.
//

#import "OTCodeViewController.h"
#import "IQKeyboardManager.h"
#import "NSUserDefaults+OT.h"
#import "UITextField+indentation.h"
#import "UIView+entourage.h"
#import "OTOnboardingService.h"
#import "SVProgressHUD.h"
#import "OTConsts.h"
#import "UIColor+entourage.h"
#import "OTAuthService.h"
#import "UIScrollView+entourage.h"
#import "NSString+Validators.h"
#import "UIBarButtonItem+factory.h"
#import "NSError+message.h"

@interface OTCodeViewController ()

@property (nonatomic, weak) IBOutlet UITextField *codeTextField;
@property (nonatomic, weak) IBOutlet UIButton *validateButton;
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *heightContraint;

@end

@implementation OTCodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"";
    [self addRegenerateBarButton];
    
    [self.codeTextField setupWithPlaceholderColor:[UIColor appTextFieldPlaceholderColor]];
    
    [[IQKeyboardManager sharedManager] setEnableAutoToolbar:NO];
    [self.validateButton setupHalfRoundedCorners];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showKeyboard:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    if([NSUserDefaults standardUserDefaults].currentUser) {
        [NSUserDefaults standardUserDefaults].temporaryUser = [NSUserDefaults standardUserDefaults].currentUser;
        [NSUserDefaults standardUserDefaults].currentUser = nil;
    }
}

#pragma mark - Private

- (void)addRegenerateBarButton {
    UIBarButtonItem *regenerateButton = [UIBarButtonItem createWithTitle:OTLocalizedString(@"doRegenerateCode").capitalizedString withTarget:self andAction:@selector(doRegenerateCode) colored:[UIColor whiteColor]];
    [self.navigationItem setRightBarButtonItem:regenerateButton];
}

- (void)viewDidAppear:(BOOL)animated {
    [self.codeTextField becomeFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)doRegenerateCode {
    NSString *phone = [NSUserDefaults standardUserDefaults].temporaryUser.phone;
    [SVProgressHUD show];
    [[OTAuthService new] regenerateSecretCode:phone.phoneNumberServerRepresentation
                                      success:^(OTUser *user) {
                                          [SVProgressHUD showSuccessWithStatus:OTLocalizedString(@"requestSent")];
                                      }
                                      failure:^(NSError *error) {
                                          [SVProgressHUD dismiss];
                                          [[[UIAlertView alloc]
                                            initWithTitle:OTLocalizedString(@"error") //@"Erreur"
                                            message:OTLocalizedString(@"requestNotSent")// @"Echec lors de la demande"
                                            delegate:nil
                                            cancelButtonTitle:nil
                                            otherButtonTitles:@"Ok",
                                            nil] show];
                                      }];
}

- (IBAction)doContinue {
    NSString *phone = [NSUserDefaults standardUserDefaults].temporaryUser.phone;
    NSString *code = self.codeTextField.text;
    NSString *deviceAPNSid = [[NSUserDefaults standardUserDefaults] objectForKey:@"device_token"];
    [SVProgressHUD show];
    
    [[OTAuthService new] authWithPhone:phone
                              password:code
                              deviceId:deviceAPNSid
                               success: ^(OTUser *user) {
                                   NSLog(@"User : %@ authenticated successfully", user.email);
                                   user.phone = phone;
                                   [SVProgressHUD dismiss];
                                   [NSUserDefaults standardUserDefaults].currentUser = user;
                                   [NSUserDefaults standardUserDefaults].temporaryUser = nil;
                                   [self performSegueWithIdentifier:@"CodeToEmailSegue" sender:self];
                               } failure: ^(NSError *error) {
                                   [SVProgressHUD showErrorWithStatus:[error userUpdateMessage]];
                               }];
}

- (void)showKeyboard:(NSNotification*)notification {
    [self.scrollView scrollToBottomFromKeyboardNotification:notification
                                         andHeightContraint:self.heightContraint];
}

@end