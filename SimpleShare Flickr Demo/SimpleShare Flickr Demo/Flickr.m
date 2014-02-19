//
//  Flickr.m
//  SimpleShare Flickr Demo
//
//  Created by Laura Skelton on 2/10/14.
//  Copyright (c) 2014 Laura Skelton. All rights reserved.
//

#import "Flickr.h"
#import "FlickrPhoto.h"

#define kFlickrAPIKey @"322a0e1aa160ff09b4b326ddf08ee76a"

@interface Flickr ()
{
    NSUInteger photoIDCounter;
    NSMutableArray *photoIDsArrayResults;
}
@end

@implementation Flickr

+ (Flickr *)sharedInstance
{
    static Flickr *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[Flickr alloc] init];
    });
    
    return _sharedInstance;
}

+ (NSString *)flickrSearchURLForSearchTerm:(NSString *) searchTerm
{
    searchTerm = [searchTerm stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return [NSString stringWithFormat:@"http://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=%@&text=%@&per_page=20&format=json&nojsoncallback=1",kFlickrAPIKey,searchTerm];
}

+ (NSString *)flickrPhotoURLForFlickrPhoto:(FlickrPhoto *) flickrPhoto size:(NSString *) size
{
    if(!size)
    {
        size = @"m";
    }
    return [NSString stringWithFormat:@"http://farm%d.staticflickr.com/%d/%@_%@_%@.jpg",flickrPhoto.farm,flickrPhoto.server,flickrPhoto.photoID,flickrPhoto.secret,size];
}

+ (NSString *)flickrInfoURLForPhotoID:(NSString *) photoID
{
    photoID = [photoID stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return [NSString stringWithFormat:@"http://api.flickr.com/services/rest/?method=flickr.photos.getInfo&api_key=%@&photo_id=%@&format=json&nojsoncallback=1",kFlickrAPIKey,photoID];
}

- (void)searchFlickrForTerm:(NSString *) term completionBlock:(FlickrSearchCompletionBlock) completionBlock
{
    NSString *searchURL = [Flickr flickrSearchURLForSearchTerm:term];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(queue, ^{
        NSError *error = nil;
        NSString *searchResultString = [NSString stringWithContentsOfURL:[NSURL URLWithString:searchURL]
                                                           encoding:NSUTF8StringEncoding
                                                              error:&error];
        if (error != nil) {
            completionBlock(term,nil,error);
        }
        else
        {
            // Parse the JSON Response
            NSData *jsonData = [searchResultString dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *searchResultsDict = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                              options:kNilOptions
                                                                                error:&error];
            if(error != nil)
            {
                completionBlock(term,nil,error);
            }
            else
            {
                NSString * status = searchResultsDict[@"stat"];
                if ([status isEqualToString:@"fail"]) {
                    NSError * error = [[NSError alloc] initWithDomain:@"FlickrSearch" code:0 userInfo:@{NSLocalizedFailureReasonErrorKey: searchResultsDict[@"message"]}];
                    completionBlock(term, nil, error);
                } else {
                
                    NSArray *objPhotos = searchResultsDict[@"photos"][@"photo"];
                    NSMutableArray *flickrPhotos = [@[] mutableCopy];
                    for(NSMutableDictionary *objPhoto in objPhotos)
                    {
                        FlickrPhoto *photo = [[FlickrPhoto alloc] init];
                        photo.farm = [objPhoto[@"farm"] intValue];
                        photo.server = [objPhoto[@"server"] intValue];
                        photo.secret = objPhoto[@"secret"];
                        photo.photoID = objPhoto[@"id"];
                        photo.title = objPhoto[@"title"];
                        
                        NSString *searchURL = [Flickr flickrPhotoURLForFlickrPhoto:photo size:@"m"];
                        NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:searchURL]
                                                                  options:0
                                                                    error:&error];
                        UIImage *image = [UIImage imageWithData:imageData];
                        photo.thumbnail = image;
                        
                        [flickrPhotos addObject:photo];
                    }
                    
                    completionBlock(term,flickrPhotos,nil);
                }
            }
        }
    });
}

- (void)loadImageForPhoto:(FlickrPhoto *)flickrPhoto thumbnail:(BOOL)thumbnail completionBlock:(FlickrPhotoCompletionBlock) completionBlock
{
    
    NSString *size = thumbnail ? @"m" : @"b";
    
    NSString *searchURL = [Flickr flickrPhotoURLForFlickrPhoto:flickrPhoto size:size];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(queue, ^{
        NSError *error = nil;
        
        NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:searchURL]
                                                  options:0
                                                    error:&error];
        if(error)
        {
            completionBlock(nil,error);
        }
        else
        {
            UIImage *image = [UIImage imageWithData:imageData];
            if([size isEqualToString:@"m"])
            {
                flickrPhoto.thumbnail = image;
            }
            else
            {
                flickrPhoto.largeImage = image;
            }
            completionBlock(image,nil);
        }
        
    });
}

- (void)getFlickrInfoForPhotoID:(NSString *) photoID completionBlock:(FlickrInfoCompletionBlock) completionBlock
{
    NSString *infoURL = [Flickr flickrInfoURLForPhotoID:photoID];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(queue, ^{
        NSError *error = nil;
        NSString *infoResultString = [NSString stringWithContentsOfURL:[NSURL URLWithString:infoURL]
                                                                encoding:NSUTF8StringEncoding
                                                                   error:&error];
        if (error != nil) {
            completionBlock(photoID,nil,error);
        }
        else
        {
            // Parse the JSON Response
            NSData *jsonData = [infoResultString dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *infoResultsDict = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                              options:kNilOptions
                                                                                error:&error];
            if(error != nil)
            {
                completionBlock(photoID,nil,error);
            }
            else
            {
                NSString * status = infoResultsDict[@"stat"];
                if ([status isEqualToString:@"fail"]) {
                    NSError * error = [[NSError alloc] initWithDomain:@"FlickrInfo" code:0 userInfo:@{NSLocalizedFailureReasonErrorKey: infoResultsDict[@"message"]}];
                    completionBlock(photoID, nil, error);
                } else {
                    
                    NSMutableDictionary *objPhoto = infoResultsDict[@"photo"];

                    FlickrPhoto *photo = [[FlickrPhoto alloc] init];
                    photo.farm = [objPhoto[@"farm"] intValue];
                    photo.server = [objPhoto[@"server"] intValue];
                    photo.secret = objPhoto[@"secret"];
                    photo.photoID = objPhoto[@"id"];
                    photo.title = objPhoto[@"title"][@"_content"];
                    
                    NSString *thumbURL = [Flickr flickrPhotoURLForFlickrPhoto:photo size:@"m"];
                    NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:thumbURL]
                                                              options:0
                                                                error:&error];
                    thumbURL = nil;
                    UIImage *image = [UIImage imageWithData:imageData];
                    imageData = nil;
                    photo.thumbnail = image;
                    image = nil;
                    
                    completionBlock(photoID,photo,nil);

                }
            }
        }
    });
}

- (void)getFlickrInfoForPhotoIDsArray:(NSArray *) photoIDsArray completionBlock:(FlickrArrayInfoCompletionBlock) completionBlock
{
    photoIDsArrayResults = [[NSMutableArray alloc] init];
    photoIDCounter = [photoIDsArray count];
    
    for (NSString *photoID in photoIDsArray) {
        NSString *infoURL = [Flickr flickrInfoURLForPhotoID:photoID];
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        
        dispatch_async(queue, ^{
            NSError *error = nil;
            NSString *infoResultString = [NSString stringWithContentsOfURL:[NSURL URLWithString:infoURL]
                                                                  encoding:NSUTF8StringEncoding
                                                                     error:&error];
            if (error != nil) {
                NSLog(@"error: %@", error);
                
                photoIDCounter --;
                if (photoIDCounter == 0) {
                    completionBlock(photoIDsArray,photoIDsArrayResults,error);
                }
            }
            else
            {
                // Parse the JSON Response
                NSData *jsonData = [infoResultString dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *infoResultsDict = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                                options:kNilOptions
                                                                                  error:&error];
                if(error != nil)
                {
                    NSLog(@"error: %@", error);
                    
                    photoIDCounter --;
                    if (photoIDCounter == 0) {
                        completionBlock(photoIDsArray,photoIDsArrayResults,error);
                    }
                }
                else
                {
                    NSString * status = infoResultsDict[@"stat"];
                    if ([status isEqualToString:@"fail"]) {
                        NSError * error = [[NSError alloc] initWithDomain:@"FlickrInfo" code:0 userInfo:@{NSLocalizedFailureReasonErrorKey: infoResultsDict[@"message"]}];
                        
                        NSLog(@"error: %@", error);
                        
                        photoIDCounter --;
                        if (photoIDCounter == 0) {
                            completionBlock(photoIDsArray,photoIDsArrayResults,error);
                        }
                        
                    } else {
                        
                        NSMutableDictionary *objPhoto = infoResultsDict[@"photo"];
                        //NSLog(@"objPhoto: %@", objPhoto);
                        //NSLog(@"objPhoto title: %@", objPhoto[@"title"][@"_content"]);
                        
                        FlickrPhoto *photo = [[FlickrPhoto alloc] init];
                        photo.farm = [objPhoto[@"farm"] intValue];
                        photo.server = [objPhoto[@"server"] intValue];
                        photo.secret = objPhoto[@"secret"];
                        photo.photoID = objPhoto[@"id"];
                        photo.title = objPhoto[@"title"][@"_content"];
                        
                        NSString *thumbURL = [Flickr flickrPhotoURLForFlickrPhoto:photo size:@"m"];
                        NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:thumbURL]
                                                                  options:0
                                                                    error:&error];
                        thumbURL = nil;
                        UIImage *image = [UIImage imageWithData:imageData];
                        imageData = nil;
                        photo.thumbnail = image;
                        image = nil;
                        
                        [photoIDsArrayResults addObject:photo];
                        
                        photoIDCounter --;
                        if (photoIDCounter == 0) {
                            completionBlock(photoIDsArray,photoIDsArrayResults,nil);
                        }
                        
                    }
                }
            }
        });

    }
    
}



@end
