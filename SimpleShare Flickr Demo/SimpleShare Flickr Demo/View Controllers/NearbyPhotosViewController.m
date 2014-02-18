//
//  NearbyPhotosViewController.m
//  SimpleShare Flickr Demo
//
//  Created by Laura Skelton on 2/10/14.
//  Copyright (c) 2014 Laura Skelton. All rights reserved.
//

#import "NearbyPhotosViewController.h"
#import "SimpleShare.h"

@interface NearbyPhotosViewController ()

@end

@implementation NearbyPhotosViewController
@synthesize nearbyPhotoIDs = _nearbyPhotoIDs, delegate;

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
    return [_nearbyPhotoIDs count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"nearbyPhotoCell"];
    
    cell.textLabel.text = [_nearbyPhotoIDs objectAtIndex:indexPath.row];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // added nearby photo
    [delegate nearbyPhotosViewControllerAddedPhoto:[_nearbyPhotoIDs objectAtIndex:indexPath.row]];
    
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Added Photo", nil) message:@"The photo was added successfully." delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
    
    // remove the item from found items list
    [_nearbyPhotoIDs removeObjectAtIndex:indexPath.row];
    
    if ([_nearbyPhotoIDs count] == 0) {
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
    [delegate nearbyPhotosViewControllerDidCancel:self];
}

@end
