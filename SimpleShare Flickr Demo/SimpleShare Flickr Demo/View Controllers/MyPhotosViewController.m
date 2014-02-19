//
//  MyPhotosViewController.m
//  SimpleShare Flickr Demo
//
//  Created by Laura Skelton on 2/10/14.
//  Copyright (c) 2014 Laura Skelton. All rights reserved.
//

#import "MyPhotosViewController.h"
#import "Flickr.h"
#import "MyPhotoDetailViewController.h"

@interface MyPhotosViewController ()

@end

@implementation MyPhotosViewController
@synthesize myPhotos = _myPhotos, myPhotoIDs = _myPhotoIDs;

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
    
    [SimpleShare sharedInstance].delegate = self;
    
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

-(void)setMyPhotoIDs:(NSMutableArray *)newMyPhotoIDs
{
    NSLog(@"setMyPhotoIDs: %@", newMyPhotoIDs);
    if (_myPhotoIDs != newMyPhotoIDs) {
        _myPhotoIDs = newMyPhotoIDs;
        _myPhotos = nil;
        
        // Update SimpleShare with the photo IDs we are sharing
        [SimpleShare sharedInstance].myItemIDs = _myPhotoIDs;
        
        [[Flickr sharedInstance] getFlickrInfoForPhotoIDsArray:_myPhotoIDs completionBlock:^(NSArray *photoIDsArray, NSArray *photoResultsArray, NSError *error) {
            if(photoResultsArray && [photoResultsArray count] > 0) {
                NSLog(@"result photos array");
                // 2
                _myPhotos = [photoResultsArray mutableCopy];
                
                // 3
                dispatch_async(dispatch_get_main_queue(), ^{
                    // reload search results data
                    NSLog(@"reloading table");
                    [self.tableView reloadData];
                });
            } else { // 1
                NSLog(@"Error getting photo info from Flickr: %@", error.localizedDescription);
            } }];
        
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
    } else if (tableView == self.tableView) {
        [self performSegueWithIdentifier:@"showPhotoDetail" sender:self];
    }
}

#pragma mark - Flickr methods
- (void)addFlickrPhoto:(FlickrPhoto *)flickrPhoto
{
    NSLog(@"adding photo: %@", flickrPhoto);
    
    if (_myPhotos == nil) {
        _myPhotos = [[NSMutableArray alloc] init];
    }
    
    [_myPhotos addObject:flickrPhoto];
    
    [self.tableView reloadData];
    
    // Update SimpleShare with the photo IDs we are sharing

    if (_myPhotoIDs == nil) {
        _myPhotoIDs = [[NSMutableArray alloc] init];
    }
    
    [_myPhotoIDs addObject:flickrPhoto.photoID];
    [SimpleShare sharedInstance].myItemIDs = _myPhotoIDs;
    NSLog(@"simpleshare myitemids: %@", [SimpleShare sharedInstance].myItemIDs);
}

#pragma mark - NearbyPhotosViewController Delegate

- (void)nearbyPhotosViewControllerAddedPhoto:(FlickrPhoto *)flickrPhoto
{
    if (_myPhotoIDs == nil) {
        _myPhotoIDs = [[NSMutableArray alloc] init];
    }
    [_myPhotoIDs addObject:flickrPhoto.photoID];
    
    // Update SimpleShare with the photo IDs we are sharing
    [SimpleShare sharedInstance].myItemIDs = _myPhotoIDs;
    
    if (_myPhotos == nil) {
        _myPhotos = [[NSMutableArray alloc] init];
    }
    
    if ([_myPhotos containsObject:flickrPhoto] == NO) {
        [_myPhotos addObject:flickrPhoto];
    }
    
    // reload table data
    [self.tableView reloadData];
    
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
    _nearbyPhotoIDs = nil;
    
    _nearbyPhotoIDs = [[NSMutableArray alloc] init];
    
    // add the first item to the array
    [_nearbyPhotoIDs addObjectsFromArray:itemIDs];
    
    [[Flickr sharedInstance] getFlickrInfoForPhotoIDsArray:itemIDs completionBlock:^(NSArray *photoIDsArray, NSArray *photoResultsArray, NSError *error) {
        if(photoResultsArray && [photoResultsArray count] > 0) {
            NSLog(@"result photos array");
            // 2
            _nearbyPhotos = [photoResultsArray mutableCopy];
            
            // 3
            dispatch_async(dispatch_get_main_queue(), ^{
                // pop up nearby photos controller to show found photo
                [self performSegueWithIdentifier:@"addNearbyPhotos" sender:self];
            });
        } else { // 1
            NSLog(@"Error getting photo info from Flickr: %@", error.localizedDescription);
        } }];
    
}

- (void)simpleShareFoundMoreItems:(NSArray *)itemIDs
{
    // add the new item to the array
    [_nearbyPhotoIDs addObjectsFromArray:itemIDs];
    
    [[Flickr sharedInstance] getFlickrInfoForPhotoIDsArray:itemIDs completionBlock:^(NSArray *photoIDsArray, NSArray *photoResultsArray, NSError *error) {
        if(photoResultsArray && [photoResultsArray count] > 0) {
            NSLog(@"result photos array");
            // 2
            [_nearbyPhotos addObjectsFromArray:photoResultsArray];
            
            // 3
            dispatch_async(dispatch_get_main_queue(), ^{
                // update Nearby Photos controller
                [_nearbyPhotosController setNearbyPhotos:_nearbyPhotos];
                [_nearbyPhotosController.tableView reloadData];
            });
        } else { // 1
            NSLog(@"Error getting photo info from Flickr: %@", error.localizedDescription);
        } }];
    
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
        NSLog(@"performing segue");
        UINavigationController *navController = (UINavigationController *)[segue destinationViewController];
        _nearbyPhotosController = (NearbyPhotosViewController *)[navController topViewController];
        [_nearbyPhotosController setDelegate:self];
        [_nearbyPhotosController setNearbyPhotos:_nearbyPhotos];
        NSLog(@"set nearbyphotos: %@", _nearbyPhotos);

    }
    else if ([segue.identifier isEqualToString:@"showPhotoDetail"]) {
        
        MyPhotoDetailViewController *detailController = (MyPhotoDetailViewController *)segue.destinationViewController;
        detailController.flickrPhoto = [_myPhotos objectAtIndex:self.tableView.indexPathForSelectedRow.row];
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
    searchResultsArray = nil;
    [self.searchDisplayController.searchResultsTableView reloadData];
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