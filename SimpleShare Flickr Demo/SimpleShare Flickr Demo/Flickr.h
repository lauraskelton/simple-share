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
typedef void (^FlickrInfoCompletionBlock)(NSString *photoID, FlickrPhoto *photo, NSError *error);
typedef void (^FlickrArrayInfoCompletionBlock)(NSArray *photoIDsArray, NSArray *photosArray, NSError *error);

@interface Flickr : NSObject

@property(strong) NSString *apiKey;

+ (Flickr *)sharedInstance;
- (void)searchFlickrForTerm:(NSString *) term completionBlock:(FlickrSearchCompletionBlock) completionBlock;
- (void)loadImageForPhoto:(FlickrPhoto *)flickrPhoto thumbnail:(BOOL)thumbnail completionBlock:(FlickrPhotoCompletionBlock) completionBlock;
+ (NSString *)flickrPhotoURLForFlickrPhoto:(FlickrPhoto *) flickrPhoto size:(NSString *) size;
- (void)getFlickrInfoForPhotoID:(NSString *) photoID completionBlock:(FlickrInfoCompletionBlock) completionBlock;
- (void)getFlickrInfoForPhotoIDsArray:(NSArray *) photoIDsArray completionBlock:(FlickrArrayInfoCompletionBlock) completionBlock;

@end
