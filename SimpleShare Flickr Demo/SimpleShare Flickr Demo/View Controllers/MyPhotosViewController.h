//
//  MyPhotosViewController.h
//  SimpleShare Flickr Demo
//
//  Created by Laura Skelton on 2/10/14.
//  Copyright (c) 2014 Laura Skelton. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NearbyPhotosViewController.h"
#import "SimpleShare.h"

@interface MyPhotosViewController : UITableViewController <NearbyPhotosViewControllerDelegate, SimpleShareDelegate,UISearchDisplayDelegate, UISearchBarDelegate>
{
    NearbyPhotosViewController *_nearbyPhotosController;
    NSMutableArray *_nearbyPhotos;
    IBOutlet UIBarButtonItem *_findPhotosButton;
    IBOutlet UIBarButtonItem *_sharePhotosButton;
    UIBarButtonItem *_findingPhotosActivityIndicator;
    
    NSMutableArray *searchResultsArray;
}

@property (nonatomic, retain) NSMutableArray *myPhotos;
@property (nonatomic, retain) NSMutableArray *myPhotoIDs;

-(IBAction)findNearbyPhotos:(id)sender;
-(IBAction)shareMyPhotos:(id)sender;
-(IBAction)stopSharingMyPhotos:(id)sender;

@end