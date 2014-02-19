//
//  MyPhotoDetailViewController.h
//  SimpleShare Flickr Demo
//
//  Created by Laura Skelton on 2/18/14.
//  Copyright (c) 2014 Laura Skelton. All rights reserved.
//

#import <UIKit/UIKit.h>
@class FlickrPhoto;

@interface MyPhotoDetailViewController : UIViewController
{
    IBOutlet UIImageView *largePhotoImageView;
}

@property (nonatomic, retain) FlickrPhoto *flickrPhoto;

@end
