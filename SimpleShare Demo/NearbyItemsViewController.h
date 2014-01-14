//
//  NearbyItemsViewController.h
//  SimpleShare Demo
//
//  Created by Laura Skelton on 1/11/14.
//  Copyright (c) 2014 Laura Skelton. All rights reserved.
//

#import <UIKit/UIKit.h>

@class  NearbyItemsViewController;

@protocol NearbyItemsViewControllerDelegate <NSObject>
- (void)nearbyItemsViewControllerAddedItem:(NSString *)itemID;
- (void)nearbyItemsViewControllerDidCancel:(NearbyItemsViewController *)controller;
@end

@interface NearbyItemsViewController : UITableViewController

@property (nonatomic, assign) id <NearbyItemsViewControllerDelegate> delegate;
@property (nonatomic, retain) NSMutableArray *nearbyItemIDs;

-(IBAction)cancel:(id)sender;

@end
