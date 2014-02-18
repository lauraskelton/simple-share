//
//  FlickrPhoto.h
//  SimpleShare Flickr Demo
//
//  Created by Laura Skelton on 2/10/14.
//  Copyright (c) 2014 Laura Skelton. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FlickrPhoto : NSObject
@property(nonatomic,strong) UIImage *thumbnail;
@property(nonatomic,strong) UIImage *largeImage;
@property(nonatomic,strong) NSString *title;
@property(nonatomic, strong) NSString *photoID;

// Lookup info
@property(nonatomic) NSInteger farm;
@property(nonatomic) NSInteger server;
@property(nonatomic,strong) NSString *secret;

@end
