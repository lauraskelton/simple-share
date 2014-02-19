//
//  MyPhotoDetailViewController.m
//  SimpleShare Flickr Demo
//
//  Created by Laura Skelton on 2/18/14.
//  Copyright (c) 2014 Laura Skelton. All rights reserved.
//

#import "MyPhotoDetailViewController.h"
#import "Flickr.h"

@interface MyPhotoDetailViewController ()

@end

@implementation MyPhotoDetailViewController
@synthesize flickrPhoto = _flickrPhoto;


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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ((_flickrPhoto.largeImage == nil) || (_flickrPhoto.largeImage.size.width == 0)) {
        largePhotoImageView.image = _flickrPhoto.thumbnail;
        
    } else {
        largePhotoImageView.image = _flickrPhoto.largeImage;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ((_flickrPhoto.largeImage == nil) || (_flickrPhoto.largeImage.size.width == 0)) {
        
        NSLog(@"image is nil");
        
        [[Flickr sharedInstance] loadImageForPhoto:_flickrPhoto thumbnail:NO completionBlock:^(UIImage *photoImage, NSError *error) {
            if(photoImage != nil) {
                NSLog(@"result photo image");
                // 2
                self.flickrPhoto.largeImage = photoImage;
                
                // 3
                dispatch_async(dispatch_get_main_queue(), ^{
                    // reload search results data
                    NSLog(@"reloading detail view");
                    largePhotoImageView.image = photoImage;
                });
            } else { // 1
                NSLog(@"Error getting large photo from Flickr: %@", error.localizedDescription);
            } }];
        
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Set Properties

-(void)setFlickrPhoto:(FlickrPhoto *)newFlickrPhoto
{
    if (_flickrPhoto != newFlickrPhoto) {
        _flickrPhoto = newFlickrPhoto;
        NSLog(@"should reload detail view");
        // reload detail view
        self.title = _flickrPhoto.title;
        
    }
}

@end
