//
//  OTMapOptionsViewController.m
//  entourage
//
//  Created by Mihai Ionescu on 04/04/16.
//  Copyright © 2016 OCTO Technology. All rights reserved.
//

#import "OTMapOptionsViewController.h"

@interface OTMapOptionsViewController ()

@property (nonatomic, weak) IBOutlet UIButton *createTourButton;
@property (nonatomic, weak) IBOutlet UILabel *createTourLabel;
@property (nonatomic, weak) IBOutlet UIButton *togglePOIButton;
@property (nonatomic, weak) IBOutlet UILabel *togglePOILabel;



@property (nonatomic) BOOL isPOIVisible;

@end

@implementation OTMapOptionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if (!CGPointEqualToPoint(self.fingerPoint, CGPointZero)) {
        self.togglePOILabel.hidden = YES;
        self.togglePOIButton.hidden = YES;
        self.createTourLabel.hidden = YES;
        
        self.createTourButton.hidden = YES;
        [self addOptionWithIcon:@"createMaraude" andAction:@selector(doCreateTour:)];
        
    } else {
        if (self.isPOIVisible) {
            self.togglePOILabel.text = NSLocalizedString(@"map_options_hide_poi", @"");
        }
        else {
            self.togglePOILabel.text = NSLocalizedString(@"map_options_show_poi", @"");
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)doDismiss:(id)sender {
    if ([self.mapOptionsDelegate respondsToSelector:@selector(dismissMapOptions)]) {
        [self.mapOptionsDelegate performSelector:@selector(dismissMapOptions) withObject:nil];
    }
}

- (IBAction)doCreateTour:(id)sender {
    if ([self.mapOptionsDelegate respondsToSelector:@selector(createTour)]) {
        [self.mapOptionsDelegate performSelector:@selector(createTour) withObject:nil];
    }
}

- (IBAction)doTogglePOI:(id)sender {
    if ([self.mapOptionsDelegate respondsToSelector:@selector(togglePOI)]) {
        [self.mapOptionsDelegate performSelector:@selector(togglePOI) withObject:nil];
    }
}

- (void)setIsPOIVisible:(BOOL)POIVisible {
    _isPOIVisible = POIVisible;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
 */

- (void)addOptionWithIcon:(NSString *)optionIcon
                andAction:(SEL)selector
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *image = [UIImage imageNamed:optionIcon];
    
    button.frame = CGRectMake(self.fingerPoint.x - image.size.width/2, self.fingerPoint.y+10, image.size.width, image.size.height);
    [button setImage:[UIImage imageNamed:optionIcon] forState:UIControlStateNormal];
    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

@end
