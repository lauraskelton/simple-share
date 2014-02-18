//
//  Flickr.h
//  SimpleShare Flickr Demo
//
//  Created by Laura Skelton on 2/10/14.
//  Copyright (c) 2014 Laura Skelton. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FlickrPhoto.h"

@class FlickrPhoto;

typedef void (^FlickrSearchCompletionBlock)(NSString *searchTerm, NSArray *results, NSError *error);
typedef void (^FlickrPhotoCompletionBlock)(UIImage *photoImage, NSError *error);

@interface Flickr : NSObject

@property(strong) NSString *apiKey;

+ (Flickr *)sharedInstance;
- (void)searchFlickrForTerm:(NSString *) term completionBlock:(FlickrSearchCompletionBlock) completionBlock;
+ (void)loadImageForPhoto:(FlickrPhoto *)flickrPhoto thumbnail:(BOOL)thumbnail completionBlock:(FlickrPhotoCompletionBlock) completionBlock;
+ (NSString *)flickrPhotoURLForFlickrPhoto:(FlickrPhoto *) flickrPhoto size:(NSString *) size;

@end
