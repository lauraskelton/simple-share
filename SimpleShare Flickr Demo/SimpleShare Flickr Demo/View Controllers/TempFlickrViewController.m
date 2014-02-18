//
//  TempFlickrViewController.m
//  SimpleShare Flickr Demo
//
//  Created by Laura Skelton on 2/10/14.
//  Copyright (c) 2014 Laura Skelton. All rights reserved.
//

#import "TempFlickrViewController.h"
#import "Flickr.h"

@interface TempFlickrViewController ()

@end

@implementation TempFlickrViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return [searchResultsArray count];
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if ( cell == nil ) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        FlickrPhoto *aPhoto = (FlickrPhoto *)[searchResultsArray objectAtIndex:indexPath.row];
        cell.textLabel.text = aPhoto.title;
        cell.imageView.image = aPhoto.thumbnail;
    }
    
    return cell;
}

#pragma mark - UISearchDisplayController Delegate Methods
-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    // Tells the table data source not to reload when text changes (only when hit return)
    
    searchDisplayController = controller;
    
    return NO;
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
                [searchDisplayController.searchResultsTableView reloadData];
            });
        } else { // 1
            NSLog(@"Error searching Flickr: %@", error.localizedDescription);
        } }];
}

@end
