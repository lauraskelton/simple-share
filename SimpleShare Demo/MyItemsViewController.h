//
//  MyItemsViewController.h
//  SimpleShare Demo
//
//  Created by Laura Skelton on 1/11/14.
//  Copyright (c) 2014 Laura Skelton. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NearbyItemsViewController.h"
#import "SimpleShare/SimpleShare.h"

@interface MyItemsViewController : UITableViewController <NearbyItemsViewControllerDelegate, SimpleShareDelegate>
{
    NearbyItemsViewController *_nearbyItemsController;
    NSMutableArray *_nearbyItems;
    IBOutlet UIBarButtonItem *_findItemsButton;
    IBOutlet UIBarButtonItem *_shareItemsButton;
    UIBarButtonItem *_findingItemsActivityIndicator;
}

@property (nonatomic, retain) NSMutableArray *myItemIDs;

-(IBAction)findNearbyItems:(id)sender;
-(IBAction)shareMyItems:(id)sender;
-(IBAction)stopSharingMyItems:(id)sender;

@end
