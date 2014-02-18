//
//  MyPhotosViewController.m
//  SimpleShare Flickr Demo
//
//  Created by Laura Skelton on 2/10/14.
//  Copyright (c) 2014 Laura Skelton. All rights reserved.
//

#import "MyPhotosViewController.h"
#import "Flickr.h"

@interface MyPhotosViewController ()

@end

@implementation MyPhotosViewController
@synthesize myPhotos = _myPhotos;

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
    //self.myPhotos = [[NSMutableArray alloc] initWithObjects:[[NSUUID UUID] UUIDString], [[NSUUID UUID] UUIDString], [[NSUUID UUID] UUIDString], [[NSUUID UUID] UUIDString], [[NSUUID UUID] UUIDString], nil];
#warning load previous session photo ids
    // Tell SimpleShare the item IDs we are sharing
    [SimpleShare sharedInstance].delegate = self;
    
    NSMutableArray *tmpArray;
    for (FlickrPhoto *aPhoto in _myPhotos) {
        [tmpArray addObject:aPhoto.photoID];
    }
    [SimpleShare sharedInstance].myItemIDs = tmpArray;
    tmpArray = nil;
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.tableView reloadData];
}

-(void)dealloc
{
    [SimpleShare sharedInstance].delegate = nil;
    _nearbyPhotosController = nil;
}

#pragma mark - Item IDs Array

-(void)setmyPhotos:(NSMutableArray *)newMyPhotos
{
    if (_myPhotos != newMyPhotos) {
        _myPhotos = newMyPhotos;
        
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
    if (tableView == self.tableView) {
        NSLog(@"reloading main table view");
        NSLog(@"myPhotos: %@", _myPhotos);
    }
    // Return the number of rows in the section.
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return [searchResultsArray count];
    }
    
    return [_myPhotos count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if ( cell == nil ) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    FlickrPhoto *aPhoto;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        aPhoto = (FlickrPhoto *)[searchResultsArray objectAtIndex:indexPath.row];
    } else {
        aPhoto = (FlickrPhoto *)[_myPhotos objectAtIndex:indexPath.row];
    }
    
    cell.textLabel.text = aPhoto.title;
    cell.imageView.image = aPhoto.thumbnail;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        // add this photo to my photos array
        FlickrPhoto *aPhoto = (FlickrPhoto *)[searchResultsArray objectAtIndex:indexPath.row];
        [self addFlickrPhoto:aPhoto];
        
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Added Photo", nil) message:@"The photo was added successfully." delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
        
        // remove the item from found items list
        [searchResultsArray removeObjectAtIndex:indexPath.row];
        
        if ([searchResultsArray count] == 0) {
            // dismiss the search results view since there are no more to add
            [self.searchDisplayController setActive:NO animated:YES];
        } else {
            // reload the tableview to remove the item from the search results list
            [self.searchDisplayController.searchResultsTableView reloadData];
        }
    }
}

#pragma mark - Flickr methods
- (void)addFlickrPhoto:(FlickrPhoto *)flickrPhoto
{
    [_myPhotos addObject:flickrPhoto];
    
    [self.tableView reloadData];
    
    // Update SimpleShare with the photo IDs we are sharing
    [_myPhotoIDs addObject:flickrPhoto.photoID];
    NSMutableArray *tmpArray = [SimpleShare sharedInstance].myItemIDs;
    [tmpArray addObject:flickrPhoto.photoID];
    [SimpleShare sharedInstance].myItemIDs = tmpArray;
    tmpArray = nil;
}

#pragma mark - NearbyPhotosViewController Delegate

- (void)nearbyPhotosViewControllerAddedPhoto:(NSString *)photoID
{
    [_myPhotos addObject:photoID];
    
    [self.tableView reloadData];
    
    // Update SimpleShare with the photo IDs we are sharing
    [SimpleShare sharedInstance].myItemIDs = _myPhotos;
}

- (void)nearbyPhotosViewControllerDidCancel:(NearbyPhotosViewController *)controller
{
    // update UI to show it is done looking for Photos
    [self.navigationItem setRightBarButtonItem:_findPhotosButton];
    
    // dismiss the nearby Photos view controller
    [self dismissViewControllerAnimated:YES completion:nil];
    
    // stop finding nearby items
    [[SimpleShare sharedInstance] stopFindingNearbyItems:nil];
    
}

#pragma mark - SimpleShare Delegate

- (void)simpleShareFoundFirstItems:(NSArray *)itemIDs
{
    // get rid of old found nearby items
    _nearbyPhotos = nil;
    
    _nearbyPhotos = [[NSMutableArray alloc] init];
    
    // add the first item to the array
    [_nearbyPhotos addObjectsFromArray:itemIDs];
    
    // pop up nearby items controller to show found item
    [self performSegueWithIdentifier:@"addNearbyPhotos" sender:self];
}

- (void)simpleShareFoundMoreItems:(NSArray *)itemIDs
{
    // add the new item to the array
    [_nearbyPhotos addObjectsFromArray:itemIDs];
    
    // update nearby Photos controller
    [_nearbyPhotosController setNearbyPhotoIDs:_nearbyPhotos];
    [_nearbyPhotosController.tableView reloadData];
}

- (void)simpleShareFoundNoItems:(SimpleShare *)simpleShare
{
    // update UI to show it is done looking for items
    [self.navigationItem setRightBarButtonItem:_findPhotosButton];
    
}

- (void)simpleShareDidFailWithMessage:(NSString *)failMessage
{
    // update UI to show it is not looking for items
    [self.navigationItem setRightBarButtonItem:_findPhotosButton];
    
    // update UI to indicate it is not sharing items
    _sharePhotosButton.title = @"Share";
    _sharePhotosButton.action = @selector(shareMyPhotos:);
    
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"addNearbyPhotos"]) {
        UINavigationController *navController = (UINavigationController *)[segue destinationViewController];
        _nearbyPhotosController = (NearbyPhotosViewController *)[navController topViewController];
        [_nearbyPhotosController setDelegate:self];
        [_nearbyPhotosController setNearbyPhotoIDs:_nearbyPhotos];
    }
}

#pragma mark - IBActions

-(IBAction)findNearbyPhotos:(id)sender
{
    [[SimpleShare sharedInstance] findNearbyItems:self];
    
    // update UI to indicate it is looking for Photos
    if (_findingPhotosActivityIndicator == nil) {
        UIActivityIndicatorView * activityView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 25, 25)];
        activityView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        [activityView sizeToFit];
        [activityView setAutoresizingMask:(UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin)];
        [activityView startAnimating];
        _findingPhotosActivityIndicator = [[UIBarButtonItem alloc] initWithCustomView:activityView];
        activityView = nil;
    }
    
    [self.navigationItem setRightBarButtonItem:_findingPhotosActivityIndicator];
    
}

-(IBAction)shareMyPhotos:(id)sender
{
    [[SimpleShare sharedInstance] shareMyItems:self];
    
    // update UI to indicate it is sharing items
    _sharePhotosButton.title = @"Stop Sharing";
    _sharePhotosButton.action = @selector(stopSharingMyPhotos:);
    
}

-(IBAction)stopSharingMyPhotos:(id)sender
{
    [[SimpleShare sharedInstance] stopSharingMyItems:self];
    
    // update UI to indicate it is not sharing Photos
    _sharePhotosButton.title = @"Share";
    _sharePhotosButton.action = @selector(shareMyPhotos:);
    
}

#pragma mark - UISearchDisplayController Delegate Methods
-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    // Tells the table data source not to reload when text changes (only when hit return)
    
    NSLog(@"should reload table for string: %@", searchString);
    
    return NO;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didHideSearchResultsTableView:(UITableView *)tableView
{
    [self.tableView reloadData];
    NSLog(@"reloading main table view data");
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    NSLog(@"searchbartext did end editing");
    
    NSLog(@"searching Flickr for %@", searchBar.text);
    // 1
    [[Flickr sharedInstance] searchFlickrForTerm:searchBar.text completionBlock:^(NSString *searchTerm, NSArray *results, NSError *error) {
        if(results && [results count] > 0) {
            NSLog(@"results");
            // 2
            searchResultsArray = [results mutableCopy];
            // 3
            dispatch_async(dispatch_get_main_queue(), ^{
                // reload search results data
                NSLog(@"reloading table");
                [self.searchDisplayController.searchResultsTableView reloadData];
            });
        } else { // 1
            NSLog(@"Error searching Flickr: %@", error.localizedDescription);
        } }];
}

@end