//
//  NearbyItemsViewController.m
//  SimpleShare Demo
//
//  Created by Laura Skelton on 1/11/14.
//  Copyright (c) 2014 Laura Skelton. All rights reserved.
//

#import "NearbyItemsViewController.h"
#import "SimpleShare/SimpleShare.h"

@interface NearbyItemsViewController ()

@end

@implementation NearbyItemsViewController
@synthesize nearbyItemIDs = _nearbyItemIDs, delegate;

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
    return [_nearbyItemIDs count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"nearbyItemCell"];
    
    cell.textLabel.text = [_nearbyItemIDs objectAtIndex:indexPath.row];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // add the item to my items
    [delegate nearbyItemsViewControllerAddedItem:[_nearbyItemIDs objectAtIndex:indexPath.row]];
    
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Added Item", nil) message:@"The item was added successfully." delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
    
    // remove the item from found items list
    [_nearbyItemIDs removeObjectAtIndex:indexPath.row];
    
    if ([_nearbyItemIDs count] == 0) {
        // dismiss the found items view since there are no more to add
        [self cancel:nil];
    } else {
        // reload the tableview to remove the item from the found list
        [self.tableView reloadData];
    }
    
}

#pragma mark - IBActions

-(IBAction)cancel:(id)sender
{
    [delegate nearbyItemsViewControllerDidCancel:self];
}

@end
