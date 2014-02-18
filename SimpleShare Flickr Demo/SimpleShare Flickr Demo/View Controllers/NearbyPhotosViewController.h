//
//  NearbyPhotosViewController.h
//  SimpleShare Flickr Demo
//
//  Created by Laura Skelton on 2/10/14.
//  Copyright (c) 2014 Laura Skelton. All rights reserved.
//

#import <UIKit/UIKit.h>

@class  NearbyPhotosViewController;

@protocol NearbyPhotosViewControllerDelegate <NSObject>
- (void)nearbyPhotosViewControllerAddedPhoto:(NSString *)photoID;
- (void)nearbyPhotosViewControllerDidCancel:(NearbyPhotosViewController *)controller;
@end

@interface NearbyPhotosViewController : UITableViewController

@property (nonatomic, assign) id <NearbyPhotosViewControllerDelegate> delegate;
@property (nonatomic, retain) NSMutableArray *nearbyPhotoIDs;

-(IBAction)cancel:(id)sender;

@end
