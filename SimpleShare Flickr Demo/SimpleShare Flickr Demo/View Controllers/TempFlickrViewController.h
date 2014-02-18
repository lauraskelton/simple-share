//
//  TempFlickrViewController.h
//  SimpleShare Flickr Demo
//
//  Created by Laura Skelton on 2/10/14.
//  Copyright (c) 2014 Laura Skelton. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TempFlickrViewController : UIViewController <UISearchDisplayDelegate, UISearchBarDelegate>
{
    IBOutlet UISearchDisplayController *searchDisplayController;
    NSMutableArray *searchResultsArray;
}

@end
