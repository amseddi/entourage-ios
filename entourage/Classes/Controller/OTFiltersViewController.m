//
//  OTFiltersViewController.m
//  entourage
//
//  Created by Ciprian Habuc on 20/05/16.
//  Copyright © 2016 OCTO Technology. All rights reserved.
//

#import "OTFiltersViewController.h"
#import "OTFilterCellTableViewCell.h"
#import "OTFilterRadioButton.h"
#import "UIViewController+menu.h"
#import "UIColor+entourage.h"
#import "OTConsts.h"

#import "OTEntourageFilter.h"
#import "UIBarButtonItem+factory.h"

#define FILTER_IMAGE_TAG 1
#define FILTER_DESCRIPTION_TAG 2
#define FILTER_SWITCH_TAG 3

#define FILTER_TIMEFRAME_BUTTON_START_TAG 1
#define FILTER_TIMEFRAME_BUTTON_END_TAG 3

#define FILTER_SECTION_TITLE_TAG 1

@interface OTFiltersViewController () <UITableViewDataSource, UITableViewDelegate> {
    int noImageSection;
}

@property (nonatomic, weak) IBOutlet UITableView *filterTableView;

@property (nonatomic, strong) NSArray* sections;
@property (nonatomic, strong) NSArray* items;
@property (nonatomic, strong) NSArray* maraudeIcons;

@property (nonatomic, strong) NSMutableArray* timeframeButtons;

@end

@implementation OTFiltersViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title =  OTLocalizedString(@"filters").uppercaseString;
    
    [self setupCloseModal];
    
    UIBarButtonItem *menuButton = [UIBarButtonItem createWithTitle:OTLocalizedString(@"save").capitalizedString withTarget:self andAction:@selector(saveFilters) colored:[UIColor appOrangeColor]];
    [self.navigationItem setRightBarButtonItem:menuButton];
    
    [self initData];
    
    self.filterTableView.tableFooterView = [[UIView alloc] init];
}

- (void) initData {
    self.sections = [NSMutableArray arrayWithArray: @[
                      OTLocalizedString(@"filter_maraudes_title"),
                      OTLocalizedString(@"filter_entourages_title"),
                      OTLocalizedString(@"filter_timeframe_title")
                      ]];
    
    self.items = [NSMutableArray arrayWithArray:@[
                   @[
                       @[OTLocalizedString(@"filter_maraude_medical"), kEntourageFilterMaraudeMedical],
                       @[OTLocalizedString(@"filter_maraude_bare_hands"), kEntourageFilterMaraudeBarehands],
                       @[OTLocalizedString(@"filter_maraude_alimentary"), kEntourageFilterMaraudeAlimentary],
                       ],
                   [NSMutableArray arrayWithArray:@[
                       @[OTLocalizedString(@"filter_entourage_demand"), kEntourageFilterEntourageDemand],
                       @[OTLocalizedString(@"filter_entourage_contribution"), kEntourageFilterentourageContribution],
                       @[OTLocalizedString(@"filter_entourage_show_tours"), kEntourageFilterEntourageShowTours],
                       @[OTLocalizedString(@"filter_entourage_only_my_entourages"), kEntourageFilterEntourageOnlyMyEntourages],
                       ]],
                   @[
                       @[@"", kEntourageFilterTimeframe],
                       ]
                   ]];
    
    self.maraudeIcons = @[
                          @"filter_heal",
                          @"filter_social",
                          @"filter_eat"
                          ];
    
    noImageSection = 1;
    if(!self.isProUser) {
        noImageSection = 0;
        [(NSMutableArray *)self.sections removeObjectAtIndex:0];
        [(NSMutableArray *)self.items removeObjectAtIndex:0];
        [(NSMutableArray *)[self.items objectAtIndex:0] removeObjectAtIndex:2];
    }
    self.timeframeButtons = [NSMutableArray new];
}

- (void)saveFilters {
    OTEntourageFilter *entourageFilter = [OTEntourageFilter sharedInstance];
    for (NSInteger section = 0; section < self.sections.count; section++) {
        NSArray *items = self.items[section];
        // First item is the header cell, so we start from 1
        for (NSInteger row = 1; row <= items.count; row++) {
            OTFilterCellTableViewCell *cell = [self.filterTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
            if (section != self.sections.count - 1) {
                UISwitch *switchButton = [cell viewWithTag:FILTER_SWITCH_TAG];
                [entourageFilter setFilterValue:[NSNumber numberWithBool:switchButton.isOn] forKey:cell.filterKey];
            }
            else {
                for (NSInteger tag = FILTER_TIMEFRAME_BUTTON_START_TAG; tag <= FILTER_TIMEFRAME_BUTTON_END_TAG; tag++) {
                    OTFilterRadioButton *timeframeButton = [cell.contentView viewWithTag:tag];
                    if ([timeframeButton isSelected]) {
                        NSNumber *filterValue = [timeframeButton valueForKeyPath:@"filterValue"];
                        [entourageFilter setFilterValue:filterValue forKey:cell.filterKey];
                        break;
                    }
                }
            }
        }
    }
    
    // Inform the delegate
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(filterChanged)]) {
        [self.delegate filterChanged];
    }
    
    // Dismiss the controller
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)timeframeButtonClicked:(UIButton *)sender {
    for (UIButton* timeframeButton in self.timeframeButtons) {
        [timeframeButton setSelected:NO];
    }
    [sender setSelected:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count ;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return ((NSArray*)self.items[section]).count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    OTEntourageFilter *entourageFilter = [OTEntourageFilter sharedInstance];
    
    if (indexPath.section != self.sections.count - 1) {
        if (indexPath.row == 0) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"OTFilterHeaderCell" forIndexPath:indexPath];
            
            UILabel *title = [cell viewWithTag:FILTER_SECTION_TITLE_TAG];
            [title setText:self.sections[indexPath.section]];
            
            return cell;
        }
        
        if (indexPath.section == noImageSection)
            cell = [tableView dequeueReusableCellWithIdentifier:@"OTNoImageFilterCell" forIndexPath:indexPath];
        else
            cell = [tableView dequeueReusableCellWithIdentifier:@"OTFilterCell" forIndexPath:indexPath];
        
        UIImageView *filterImage = [cell.contentView viewWithTag:FILTER_IMAGE_TAG];
        UILabel *filterDescription = [cell.contentView viewWithTag:FILTER_DESCRIPTION_TAG];
        UISwitch *filterSwitch = [cell.contentView viewWithTag:FILTER_SWITCH_TAG];
        // Image
        if (self.isProUser && indexPath.section == 0) {
            if (indexPath.row - 1 < self.maraudeIcons.count)
                [filterImage setImage:[UIImage imageNamed:self.maraudeIcons[indexPath.row-1]]];
            else
                ;
                
        }
        
        if (indexPath.section == self.sections.count - 2) {
            CGRect frame = filterDescription.frame;
            CGFloat x = frame.origin.x;
            
            frame.origin.x = 15.0f;
            frame.size.width += x-15.0f;
            filterDescription.frame = frame;
            [filterDescription setNeedsDisplay];
        }
        
        // Description
        NSArray *sectionItems = (NSArray*)self.items[indexPath.section];
        NSArray *filterItem = sectionItems[indexPath.row-1];
        [filterDescription setText:filterItem[0]];
        // Switch status
        [filterSwitch setOn:[[entourageFilter valueForFilter:filterItem[1]] boolValue]];
        
        ((OTFilterCellTableViewCell*)cell).filterKey = filterItem[1];
    }
    else {
        // Timeframe cell
        if (indexPath.row == 0) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"OTFilterHeaderCell" forIndexPath:indexPath];
            
            UILabel *title = [cell viewWithTag:FILTER_SECTION_TITLE_TAG];
            [title setText:self.sections[indexPath.section]];
            
            return cell;
        }
        
        cell = [tableView dequeueReusableCellWithIdentifier:@"OTFilterTimeframeCell" forIndexPath:indexPath];
        
        NSArray *sectionItems = (NSArray*)self.items[indexPath.section];
        NSArray *filterItem = sectionItems[indexPath.row-1];
        
        NSNumber *timeframeFilterValue = [entourageFilter valueForFilter:filterItem[1]];
        
        if (self.timeframeButtons.count == 0) {
            for (NSInteger tag = FILTER_TIMEFRAME_BUTTON_START_TAG; tag <= FILTER_TIMEFRAME_BUTTON_END_TAG; tag++) {
                UIButton *timeframeButton = [cell.contentView viewWithTag:tag];
                [self.timeframeButtons addObject:timeframeButton];
                NSNumber *filterValue = [timeframeButton valueForKeyPath:@"filterValue"];
                if ([filterValue isEqualToNumber:timeframeFilterValue]) {
                    [timeframeButton setSelected:YES];
                }
                else {
                    [timeframeButton setSelected:NO];
                }
            }
        }
        
        ((OTFilterCellTableViewCell*)cell).filterKey = filterItem[1];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section != self.sections.count - 1) {
        return 44;
    }
    else {
        if (indexPath.row == 0) {
            return 44;
        }
        return 88;
    }
}

@end