//
//  MyItemsViewController.m
//  SimpleShare Demo
//
//  Created by Laura Skelton on 1/11/14.
//  Copyright (c) 2014 Laura Skelton. All rights reserved.
//

#import "MyItemsViewController.h"

@interface MyItemsViewController ()

@end

@implementation MyItemsViewController
@synthesize myItemIDs = _myItemIDs;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Normally we'd get this array from a server that sends us a list of the user's items. For simplicity we're just creating a randomly generated array of item ID's to share.
    self.myItemIDs = [[NSMutableArray alloc] initWithObjects:[[NSUUID UUID] UUIDString], [[NSUUID UUID] UUIDString], [[NSUUID UUID] UUIDString], [[NSUUID UUID] UUIDString], [[NSUUID UUID] UUIDString], nil];
    
    // Tell SimpleShare the item IDs we are sharing
    [SimpleShare sharedInstance].delegate = self;
    [SimpleShare sharedInstance].myItemIDs = _myItemIDs;

}

-(void)dealloc
{
    [SimpleShare sharedInstance].delegate = nil;
    _nearbyItemsController = nil;
}

#pragma mark - Item IDs Array

-(void)setMyItemIDs:(NSMutableArray *)newMyItemIDs
{
    if (_myItemIDs != newMyItemIDs) {
        _myItemIDs = newMyItemIDs;
        
        // reload the table to display new added items
        [self.tableView reloadData];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [_myItemIDs count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"myItemCell"];
    
    cell.textLabel.text = [_myItemIDs objectAtIndex:indexPath.row];
    
    return cell;
}

#pragma mark - NearbyItemsViewController Delegate

- (void)nearbyItemsViewControllerAddedItem:(NSString *)itemID
{
    [_myItemIDs addObject:itemID];
    
    [self.tableView reloadData];
    
    // Update SimpleShare with the item IDs we are sharing
    [SimpleShare sharedInstance].myItemIDs = _myItemIDs;
}

- (void)nearbyItemsViewControllerDidCancel:(NearbyItemsViewController *)controller
{
    // update UI to show it is done looking for items
    [self.navigationItem setRightBarButtonItem:_findItemsButton];
    
    // dismiss the nearby items view controller
    [self dismissViewControllerAnimated:YES completion:nil];
    
    // stop finding nearby items
    [[SimpleShare sharedInstance] stopFindingNearbyItems:nil];

}

#pragma mark - SimpleShare Delegate

- (void)simpleShareFoundFirstItems:(NSArray *)itemIDs
{
    // get rid of old found nearby items
    _nearbyItems = nil;
    
    _nearbyItems = [[NSMutableArray alloc] init];
    
    // add the first item to the array
    [_nearbyItems addObjectsFromArray:itemIDs];
    
    // pop up nearby items controller to show found item
    [self performSegueWithIdentifier:@"addNearbyItems" sender:self];
}

- (void)simpleShareFoundMoreItems:(NSArray *)itemIDs
{
    // add the new item to the array
    [_nearbyItems addObjectsFromArray:itemIDs];
    
    // update nearby items controller
    [_nearbyItemsController setNearbyItemIDs:_nearbyItems];
    [_nearbyItemsController.tableView reloadData];
}

- (void)simpleShareFoundNoItems:(SimpleShare *)simpleShare
{
    // update UI to show it is done looking for items
    [self.navigationItem setRightBarButtonItem:_findItemsButton];

}

- (void)simpleShareDidFailWithMessage:(NSString *)failMessage
{
    // update UI to show it is not looking for items
    [self.navigationItem setRightBarButtonItem:_findItemsButton];
    
    // update UI to indicate it is not sharing items
    _shareItemsButton.title = @"Share";
    _shareItemsButton.action = @selector(shareMyItems:);

}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"addNearbyItems"]) {
        UINavigationController *navController = (UINavigationController *)[segue destinationViewController];
        _nearbyItemsController = (NearbyItemsViewController *)[navController topViewController];
        [_nearbyItemsController setDelegate:self];
        [_nearbyItemsController setNearbyItemIDs:_nearbyItems];
      }
}

#pragma mark - IBActions

-(IBAction)findNearbyItems:(id)sender
{
    [[SimpleShare sharedInstance] findNearbyItems:self];
    
    // update UI to indicate it is looking for items
    if (_findingItemsActivityIndicator == nil) {
        UIActivityIndicatorView * activityView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 25, 25)];
        activityView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        [activityView sizeToFit];
        [activityView setAutoresizingMask:(UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin)];
        [activityView startAnimating];
        _findingItemsActivityIndicator = [[UIBarButtonItem alloc] initWithCustomView:activityView];
        activityView = nil;
    }
    
    [self.navigationItem setRightBarButtonItem:_findingItemsActivityIndicator];

}

-(IBAction)shareMyItems:(id)sender
{
    [[SimpleShare sharedInstance] shareMyItems:self];
    
    // update UI to indicate it is sharing items
    _shareItemsButton.title = @"Stop Sharing";
    _shareItemsButton.action = @selector(stopSharingMyItems:);
    
}

-(IBAction)stopSharingMyItems:(id)sender
{
    [[SimpleShare sharedInstance] stopSharingMyItems:self];
    
    // update UI to indicate it is not sharing items
    _shareItemsButton.title = @"Share";
    _shareItemsButton.action = @selector(shareMyItems:);
    
}

@end
